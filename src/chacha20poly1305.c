/*
** This file contains the implementation for
**   - the ChaCha20 cipher
**   - the Poly1305 message digest
**
** The code was taken from the public domain implementation
** of the sqleet project (https://github.com/resilar/sqleet)
*/

#include "mystdint.h"
#include <string.h>

#define ROL32(x, c) (((x) << (c)) | ((x) >> (32-(c))))
#define ROR32(x, c) (((x) >> (c)) | ((x) << (32-(c))))

#define LOAD32_LE(p)            \
  ( ((uint32_t)((p)[0]) <<  0)  \
  | ((uint32_t)((p)[1]) <<  8)  \
  | ((uint32_t)((p)[2]) << 16)  \
  | ((uint32_t)((p)[3]) << 24)  \
  )
#define LOAD32_BE(p)            \
  ( ((uint32_t)((p)[3]) <<  0)  \
  | ((uint32_t)((p)[2]) <<  8)  \
  | ((uint32_t)((p)[1]) << 16)  \
  | ((uint32_t)((p)[0]) << 24)  \
  )

#define STORE32_LE(p, v)        \
  (p)[0] = ((v) >>  0) & 0xFF;  \
  (p)[1] = ((v) >>  8) & 0xFF;  \
  (p)[2] = ((v) >> 16) & 0xFF;  \
  (p)[3] = ((v) >> 24) & 0xFF;
#define STORE32_BE(p, v)        \
  (p)[3] = ((v) >>  0) & 0xFF;  \
  (p)[2] = ((v) >>  8) & 0xFF;  \
  (p)[1] = ((v) >> 16) & 0xFF;  \
  (p)[0] = ((v) >> 24) & 0xFF;
#define STORE64_BE(p, v)        \
  (p)[7] = ((v) >>  0) & 0xFF;  \
  (p)[6] = ((v) >>  8) & 0xFF;  \
  (p)[5] = ((v) >> 16) & 0xFF;  \
  (p)[4] = ((v) >> 24) & 0xFF;  \
  (p)[3] = ((v) >> 32) & 0xFF;  \
  (p)[2] = ((v) >> 40) & 0xFF;  \
  (p)[1] = ((v) >> 48) & 0xFF;  \
  (p)[0] = ((v) >> 56) & 0xFF;

/*
 * ChaCha20 stream cipher
 */
static void chacha20_block(unsigned char out[64], const uint32_t in[16])
{
  int i;
  uint32_t x[16];
  memcpy(x, in, sizeof(uint32_t) * 16);

  #define QR(x, a, b, c, d)                           \
  x[a] += x[b]; x[d] ^= x[a]; x[d] = ROL32(x[d], 16); \
  x[c] += x[d]; x[b] ^= x[c]; x[b] = ROL32(x[b], 12); \
  x[a] += x[b]; x[d] ^= x[a]; x[d] = ROL32(x[d],  8); \
  x[c] += x[d]; x[b] ^= x[c]; x[b] = ROL32(x[b],  7);
  for (i = 0; i < 10; i++)
  {
    /* Column round */
    QR(x, 0, 4, 8, 12)
    QR(x, 1, 5, 9, 13)
    QR(x, 2, 6, 10, 14)
    QR(x, 3, 7, 11, 15)
    /* Diagonal round */
    QR(x, 0, 5, 10, 15)
    QR(x, 1, 6, 11, 12)
    QR(x, 2, 7, 8, 13)
    QR(x, 3, 4, 9, 14)
  }
  #undef QR

  for (i = 0; i < 16; i++)
  {
    const uint32_t v = x[i] + in[i];
    STORE32_LE(&out[4*i], v);
  }
}

void chacha20_xor(unsigned char* data, size_t n, const unsigned char key[32],
                  const unsigned char nonce[12], uint32_t counter)
{
  size_t i;
  uint32_t state[16];
  unsigned char block[64];
  static const unsigned char sigma[16] = "expand 32-byte k";

  state[ 0] = LOAD32_LE(sigma +  0);
  state[ 1] = LOAD32_LE(sigma +  4);
  state[ 2] = LOAD32_LE(sigma +  8);
  state[ 3] = LOAD32_LE(sigma + 12);

  state[ 4] = LOAD32_LE(key +  0);
  state[ 5] = LOAD32_LE(key +  4);
  state[ 6] = LOAD32_LE(key +  8);
  state[ 7] = LOAD32_LE(key + 12);
  state[ 8] = LOAD32_LE(key + 16);
  state[ 9] = LOAD32_LE(key + 20);
  state[10] = LOAD32_LE(key + 24);
  state[11] = LOAD32_LE(key + 28);

  state[12] = counter;

  state[13] = LOAD32_LE(nonce + 0);
  state[14] = LOAD32_LE(nonce + 4);
  state[15] = LOAD32_LE(nonce + 8);

  while (n >= 64)
  {
    chacha20_block(block, state);
    for (i = 0; i < 64; i++)
    {
      data[i] ^= block[i];
    }
    state[12]++;
    data += 64;
    n -= 64;
  }

  if (n > 0)
  {
    chacha20_block(block, state);
    for (i = 0; i < n; i++)
    {
      data[i] ^= block[i];
    }
  }
}

/*
 * Poly1305 authentication tags
 */
void poly1305(const unsigned char* msg, size_t n, const unsigned char key[32],
              unsigned char tag[16])
{
  uint32_t hibit;
  uint64_t d0, d1, d2, d3, d4;
  uint32_t h0, h1, h2, h3, h4;
  uint32_t r0, r1, r2, r3, r4;
  uint32_t s1, s2, s3, s4;
  unsigned char buf[16];

  hibit = 1 << 24;
  h0 = h1 = h2 = h3 = h4 = 0;
  r0 = (LOAD32_LE(key +  0) >> 0) & 0x03FFFFFF;
  r1 = (LOAD32_LE(key +  3) >> 2) & 0x03FFFF03; s1 = r1 * 5;
  r2 = (LOAD32_LE(key +  6) >> 4) & 0x03FFC0FF; s2 = r2 * 5;
  r3 = (LOAD32_LE(key +  9) >> 6) & 0x03F03FFF; s3 = r3 * 5;
  r4 = (LOAD32_LE(key + 12) >> 8) & 0x000FFFFF; s4 = r4 * 5;
  while (n >= 16)
  {
process_block:
    h0 += (LOAD32_LE(msg +  0) >> 0) & 0x03FFFFFF;
    h1 += (LOAD32_LE(msg +  3) >> 2) & 0x03FFFFFF;
    h2 += (LOAD32_LE(msg +  6) >> 4) & 0x03FFFFFF;
    h3 += (LOAD32_LE(msg +  9) >> 6) & 0x03FFFFFF;
    h4 += (LOAD32_LE(msg + 12) >> 8) | hibit;

    #define MUL(a,b) ((uint64_t)(a) * (b))
    d0 = MUL(h0,r0) + MUL(h1,s4) + MUL(h2,s3) + MUL(h3,s2) + MUL(h4,s1);
    d1 = MUL(h0,r1) + MUL(h1,r0) + MUL(h2,s4) + MUL(h3,s3) + MUL(h4,s2);
    d2 = MUL(h0,r2) + MUL(h1,r1) + MUL(h2,r0) + MUL(h3,s4) + MUL(h4,s3);
    d3 = MUL(h0,r3) + MUL(h1,r2) + MUL(h2,r1) + MUL(h3,r0) + MUL(h4,s4);
    d4 = MUL(h0,r4) + MUL(h1,r3) + MUL(h2,r2) + MUL(h3,r1) + MUL(h4,r0);
    #undef MUL

    h0 = d0 & 0x03FFFFFF; d1 += (d0 >> 26);
    h1 = d1 & 0x03FFFFFF; d2 += (d1 >> 26);
    h2 = d2 & 0x03FFFFFF; d3 += (d2 >> 26);
    h3 = d3 & 0x03FFFFFF; d4 += (d3 >> 26);
    h4 = d4 & 0x03FFFFFF; h0 += (d4 >> 26) * 5;

    msg += 16;
    n -= 16;
  }
  if (n)
  {
    size_t i;
    for (i = 0; i < n; i++) buf[i] = msg[i];
    buf[i++] = 1;
    while (i < 16) buf[i++] = 0;
    msg = buf;
    hibit = 0;
    n = 16;
    goto process_block;
  }

  r0 = h0 + 5;
  r1 = h1 + (r0 >> 26); *(volatile uint32_t *)&r0 = 0;
  r2 = h2 + (r1 >> 26); *(volatile uint32_t *)&r1 = 0;
  r3 = h3 + (r2 >> 26); *(volatile uint32_t *)&r2 = 0;
  r4 = h4 + (r3 >> 26); *(volatile uint32_t *)&r3 = 0;
  h0 = h0 + (r4 >> 26) * 5; *(volatile uint32_t *)&r4 = 0;

  d0 = (uint64_t)LOAD32_LE(key + 16) + (h0 >>  0) + (h1 << 26);
  d1 = (uint64_t)LOAD32_LE(key + 20) + (h1 >>  6) + (h2 << 20) + (d0 >> 32);
  d2 = (uint64_t)LOAD32_LE(key + 24) + (h2 >> 12) + (h3 << 14) + (d1 >> 32);
  d3 = (uint64_t)LOAD32_LE(key + 28) + (h3 >> 18) + (h4 <<  8) + (d2 >> 32);

  STORE32_LE(tag +  0, d0); *(volatile uint32_t *)&s1 = 0;
  STORE32_LE(tag +  4, d1); *(volatile uint32_t *)&s2 = 0;
  STORE32_LE(tag +  8, d2); *(volatile uint32_t *)&s3 = 0;
  STORE32_LE(tag + 12, d3); *(volatile uint32_t *)&s4 = 0;
  *(volatile uint64_t *)&d0 = 0; *(volatile uint32_t *)&h0 = 0;
  *(volatile uint64_t *)&d1 = 0; *(volatile uint32_t *)&h1 = 0;
  *(volatile uint64_t *)&d2 = 0; *(volatile uint32_t *)&h2 = 0;
  *(volatile uint64_t *)&d3 = 0; *(volatile uint32_t *)&h3 = 0;
  *(volatile uint64_t *)&d4 = 0; *(volatile uint32_t *)&h4 = 0;
}

int poly1305_tagcmp(const unsigned char tag1[16], const unsigned char tag2[16])
{
  unsigned int d = 0;
  d |= tag1[ 0] ^ tag2[ 0];
  d |= tag1[ 1] ^ tag2[ 1];
  d |= tag1[ 2] ^ tag2[ 2];
  d |= tag1[ 3] ^ tag2[ 3];
  d |= tag1[ 4] ^ tag2[ 4];
  d |= tag1[ 5] ^ tag2[ 5];
  d |= tag1[ 6] ^ tag2[ 6];
  d |= tag1[ 7] ^ tag2[ 7];
  d |= tag1[ 8] ^ tag2[ 8];
  d |= tag1[ 9] ^ tag2[ 9];
  d |= tag1[10] ^ tag2[10];
  d |= tag1[11] ^ tag2[11];
  d |= tag1[12] ^ tag2[12];
  d |= tag1[13] ^ tag2[13];
  d |= tag1[14] ^ tag2[14];
  d |= tag1[15] ^ tag2[15];
  return d;
}

/*
 * Platform-specific entropy functions for seeding RNG
 */
#if defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
#define RtlGenRandom SystemFunction036
BOOLEAN NTAPI RtlGenRandom(PVOID RandomBuffer, ULONG RandomBufferLength);
#pragma comment(lib, "advapi32.lib")
static size_t entropy(void* buf, size_t n)
{
  return RtlGenRandom(buf, n) ? n : 0;
}
#elif defined(__linux__) || defined(__unix__) || defined(__APPLE__)
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

#ifdef __linux__
#include <sys/ioctl.h>
/* musl does not have <linux/random.h> so let's define RNDGETENTCNT here */
#ifndef RNDGETENTCNT
#define RNDGETENTCNT _IOR('R', 0x00, int)
#endif
#endif

/* Returns the number of urandom bytes read (either 0 or n) */
static size_t read_urandom(void* buf, size_t n)
{
  size_t i;
  ssize_t ret;
  int fd, count;
  struct stat st;
  int errnold = errno;

  do
  {
    fd = open("/dev/urandom", O_RDONLY, 0);
  }
  while (fd == -1 && errno == EINTR);
  if (fd == -1)
    goto fail;
  fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC);

  /* Check the sanity of the device node */
  if (fstat(fd, &st) == -1 || !S_ISCHR(st.st_mode)
                         #ifdef __linux__
                           || ioctl(fd, RNDGETENTCNT, &count) == -1
                         #endif
     )
  {
    close(fd);
    goto fail;
  }

  /* Read bytes */
  for (i = 0; i < n; i += ret)
  {
    while ((ret = read(fd, (char *)buf + i, n - i)) == -1)
    {
      if (errno != EAGAIN && errno != EINTR)
      {
        close(fd);
        goto fail;
      }
    }
  }
  close(fd);

  /* Verify that the random device returned non-zero data */
  for (i = 0; i < n; i++)
  {
    if (((unsigned char*) buf)[i] != 0)
    {
      errno = errnold;
      return n;
    }
  }

  /* Tiny n may unintentionally fall through! */
fail:
  fprintf(stderr, "bad /dev/urandom RNG)\n");
  abort(); /* PANIC! */
  return 0;
}

static size_t entropy(void* buf, size_t n)
{
#if defined(__linux__) && defined(SYS_getrandom)
  if (syscall(SYS_getrandom, buf, n, 0) == n)
    return n;
#elif defined(SYS_getentropy)
  if (syscall(SYS_getentropy, buf, n) == 0)
    return n;
#endif
  return read_urandom(buf, n);
}
#else
# error "Secure pseudorandom number generator not implemented for this OS"
#endif

/*
 * ChaCha20 random number generator
 */
void chacha20_rng(void* out, size_t n)
{
  static size_t available = 0;
  static uint32_t counter = 0;
  static unsigned char key[32], nonce[12], buffer[64] = { 0 };

#if SQLITE_THREADSAFE
  sqlite3_mutex* mutex = sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_PRNG);
  sqlite3_mutex_enter(mutex);
#endif

  while (n > 0)
  {
    size_t m;
    if (available == 0)
    {
      if (counter == 0)
      {
        if (entropy(key, sizeof(key)) != sizeof(key))
          abort();
        if (entropy(nonce, sizeof(nonce)) != sizeof(nonce))
          abort();
      }
      chacha20_xor(buffer, sizeof(buffer), key, nonce, counter++);
      available = sizeof(buffer);
    }
    m = (available < n) ? available : n;
    memcpy(out, buffer + (sizeof(buffer) - available), m);
    out = (unsigned char *)out + m;
    available -= m;
    n -= m;
  }

#if SQLITE_THREADSAFE
  sqlite3_mutex_leave(mutex);
#endif
}
