#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <x86intrin.h>

#ifdef __cplusplus
extern "C" {
#endif

#define NUM_EXERCISES 8
#define ITERATIONS 1000
#define END_PATTERN 0xdeadcafe

/* Function prototypes */
uint64_t asm_sum_by_value(uint64_t x, uint64_t y);
void asm_sum_by_ref(uint64_t *x, uint64_t *y, uint64_t *ret);
uint64_t asm_mul(uint32_t x, uint32_t y);
uint32_t asm_sum8(uint16_t a1, uint16_t a2, uint16_t a3, uint16_t a4,
                  uint16_t a5, uint16_t a6, uint16_t a7, uint16_t a8);
void asm_sum_array(uint32_t x[4], uint32_t y[4], uint32_t ret[4]);
uint16_t asm_min_array(uint16_t x[4]);
void memcpy_bytes(const void *src, void *dst, const uint32_t num_bytes);
void memcpy_bits(const void *src, void *dst, const uint32_t num_bits);

typedef int (*exercise_t)(void);

/*
 * Exercise 1: Implement a function which adds two values (a and b) and
 *             return the result (as function return)
 */
static int
exercise1(void)
{
        uint64_t a = rand() % UINT32_MAX;
        uint64_t b = rand() % UINT32_MAX;
        uint64_t expected_result = a + b;
        uint64_t ret;

        /* Implement function in assembly (in asm_functions.asm) */
        ret = asm_sum_by_value(a, b);

        if (ret != expected_result) {
                printf("Wrong output\n");
                return -1;
        }

        printf("Correct output\n");
        return 0;
}

/*
 * Exercise 2: Implement a function which adds two values (a and b) and
 *             return the result (all three parameters passed as reference)
 */
static int
exercise2(void)
{
        uint64_t a = rand() % UINT32_MAX;
        uint64_t b = rand() % UINT32_MAX;
        uint64_t expected_result = a + b;
        uint64_t ret;

        /* Implement function in assembly (in asm_functions.asm) */
        asm_sum_by_ref(&a, &b, &ret);

        if (ret != expected_result) {
                printf("Wrong output\n");
                return -1;
        }

        printf("Correct output\n");
        return 0;
}

/*
 * Exercise 3: Implement a function which multiplies two 32-bit values (a and b) and
 *             return the 64-bit result
 */
static int
exercise3(void)
{
        uint32_t a = rand() % UINT32_MAX;
        uint32_t b = rand() % UINT32_MAX;
        uint64_t expected_result = (uint64_t) a * b;
        uint64_t ret;

        /* Implement function in assembly (in asm_functions.asm) */
        ret = asm_mul(a, b);

        if (ret != expected_result) {
                printf("Wrong output\n");
                return -1;
        }

        printf("Correct output\n");
        return 0;
}

/*
 * Exercise 4: Implement a function which adds eight 16-bit values
 *             and return the 32-bit result
 */
static int
exercise4(void)
{
        uint16_t a1 = rand() % UINT16_MAX;
        uint16_t a2 = rand() % UINT16_MAX;
        uint16_t a3 = rand() % UINT16_MAX;
        uint16_t a4 = rand() % UINT16_MAX;
        uint16_t a5 = rand() % UINT16_MAX;
        uint16_t a6 = rand() % UINT16_MAX;
        uint16_t a7 = rand() % UINT16_MAX;
        uint16_t a8 = rand() % UINT16_MAX;
        uint32_t expected_result = (uint32_t) a1 + (uint32_t) a2 +
                                   (uint32_t) a3 + (uint32_t) a4 +
                                   (uint32_t) a5 + (uint32_t) a6 +
                                   (uint32_t) a7 + (uint32_t) a8;
        uint32_t ret;

        /* Implement function in assembly (in asm_functions.asm) */
        ret = asm_sum8(a1, a2, a3, a4, a5, a6, a7, a8);

        if (ret != expected_result) {
                printf("Wrong output\n");
                return -1;
        }

        printf("Correct output\n");
        return 0;
}

/*
 * Exercise 5: Implement a function which adds two arrays (a and b) and
 *             return the result values in the passed array (ret)
 */
static int
exercise5(void)
{
        uint32_t a[4];
        uint32_t b[4];
        uint32_t expected_result[4];
        unsigned i, j;
        uint32_t ret[4];

        /* Run tests with randomised input ITERATIONS amount of times */
        for (j = 0; j < ITERATIONS; j++) {

                /* Fill the array with 4 random values */
                for (i = 0; i < 4; i++) {
                        a[i] = rand();
                        b[i] = rand();
                }

                for (i = 0; i < 4; i++)
                        expected_result[i] = a[i] + b[i];

                /* Implement function in assembly (in asm_functions.asm) */
                asm_sum_array(a, b, ret);

                for (i = 0; i < 4; i++) {
                        if (ret[i] != expected_result[i]) {
                                printf("i=%u Wrong a=%" PRIu32 " b=%" PRIu32
                                       " expected=%" PRIu32 " ret=%" PRIu32 "\n",
                                       i, a[i], b[i], expected_result[i], ret[i]);
                                printf("expected - ret=%" PRIu32 "\n",
                                       expected_result[i] - ret[i]);
                                printf("Wrong output\n");
                                return -1;
                        } 
                        // else {
                        //         printf("i=%u Correct a=%" PRIu32 " b=%" PRIu32
                        //               " expected=%" PRIu32 " ret=%" PRIu32 "\n",
                        //               i, a[i], b[i], expected_result[i], ret[i]);
                        // }
                }
        }

        printf("Correct output\n");
        return 0;
}

/*
 * Exercise 6: Implement a function which find the minimum value of
 *             an array of 4 16-bit values
 */
static int
exercise6(void)
{
        uint16_t a[4];
        uint16_t expected_result;
        uint16_t ret;
        unsigned i, j;

        for (j = 0; j < ITERATIONS; j++) {

                expected_result = 0xFFFF;

                /* Fill the array with 4 random values */
                for (i = 0; i < 4; i ++) {
                        a[i] = rand();
                        // printf("Generated value: %" PRIu16 "\n", a[i]);

                        if (a[i] < expected_result)
                                expected_result = a[i];
                }
                // expected_result = 1;
                // a[0] = 1;
                // a[1] = 2;
                // a[2] = 3;
                // a[3] = 4;

                printf("Array values: %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 "\n",
                       a[0], a[1], a[2], a[3]);

                /* Implement function in assembly (in asm_functions.asm) */
                ret = asm_min_array(a);

                if (ret != expected_result) {
                        printf("Expected min=%" PRIu16 " ret=%" PRIu16 "\n",
                               expected_result, ret);
                        printf("Wrong output\n");
                        return -1;
                }
        }

        printf("Correct output\n");
        return 0;
}

#define BUF_SIZE 16384
#define BENCH_ITERATIONS 1000000
/*
 * Exercise 7: Implement a function which copies "num_bytes" from src to dst
 */
static int
exercise7(void)
{
        uint32_t num_bytes;
        uint32_t i;
        uint8_t src[256];
        uint8_t src_cpy[256];

        for (i = 0; i < sizeof(src); i++){
                src[i] = (uint8_t) i;
                src_cpy[i] = (uint8_t) i;
        }
        for (num_bytes = 0; num_bytes <= sizeof(src); num_bytes++) {
                const uint64_t end_pattern = END_PATTERN;
                uint8_t dst[256 + 8];

                /* Reset destination buffer after each test */
                memset(dst, 0, sizeof(dst));
                memcpy(dst + num_bytes, &end_pattern, 8);

                memcpy_bytes(dst, src, num_bytes);

                if (memcmp(src_cpy, dst, num_bytes) != 0) {
                        printf("Wrong output (num bytes = %u)\n", num_bytes);
                        return -1;
                }

                if (memcmp(dst + num_bytes, &end_pattern, 8) != 0) {
                        printf("Tail overwritten (num bytes = %u)\n", num_bytes);
                        return -1;
                }
        }
        printf("Correct output\n");

        /* Benchmark */
        uint8_t large_src[BUF_SIZE];
        uint8_t large_dst[BUF_SIZE];
        uint64_t start_tsc = __rdtsc();

        for (i = 0; i < BENCH_ITERATIONS; i++)
                memcpy_bytes(large_dst, large_src, BUF_SIZE);

        uint64_t end_tsc = __rdtsc();

        printf("Cycles per iteration (copying %u bytes) = %.2f\n", BUF_SIZE, (double) (end_tsc - start_tsc) / BENCH_ITERATIONS);
        printf("Cycles/B = %.2f\n", (double) ((end_tsc - start_tsc) / BENCH_ITERATIONS) / BUF_SIZE);
        return 0;
}

/*
 * Exercise 8: Implement a function which copies "num_bits" from src to dst.
 *             Note that last byte will be a partial byte, so only some bits
 *             will be copied.
 */
static int
exercise8(void)
{
        uint32_t i;
        uint8_t src[256];
        uint8_t src_cpy[256];

        for (i = 0; i < sizeof(src); i++){
                src[i] = (uint8_t) i;
                src_cpy[i] = (uint8_t) i;
        }

        for (i = 0; i < ITERATIONS; i++) {
                uint8_t dst[256 + 8];
                const uint64_t end_pattern = END_PATTERN;
                const uint32_t num_bits = rand() % (sizeof(src)*8);
                const uint32_t num_full_bytes = num_bits >> 3;
                const uint32_t num_bytes = (num_bits + 7) >> 3;

                /* Reset destination buffer after each test */
                memset(dst, 0, sizeof(dst));
                memcpy(dst + num_bytes, &end_pattern, 8);

                /* Set last byte to 0xff */
                if ((num_bits % 8) != 0)
                        dst[num_full_bytes] = 0xff;

                memcpy_bits(dst, src, num_bits);
                if (memcmp(src_cpy, dst, num_full_bytes) != 0) {
                        printf("Wrong output (full bytes) (num bytes = %u)\n",
                               num_full_bytes);
                        return -1;
                }

                if (memcmp(dst + num_bytes, &end_pattern, 8) != 0) {
                        printf("Tail overwritten (full bytes) (num bytes = %u)\n",
                               num_full_bytes);
                        return -1;
                }
                const uint32_t remaining_bits = num_bits & 0x7;
                if (remaining_bits > 0) {
                        const uint8_t last_src_byte = src_cpy[num_full_bytes];
                        const uint8_t last_dst_byte = dst[num_full_bytes];

                        const uint8_t valid_bit_mask = (uint8_t)-1 << (8 - remaining_bits);
                        const uint8_t last_src_bits = last_src_byte & valid_bit_mask;
                        const uint8_t last_dst_bits = last_dst_byte & valid_bit_mask;

                        if (last_src_bits != last_dst_bits) {
                                printf("Wrong output (partial byte)\n");
                                return -1;
                        }

                        const uint8_t trailing_bit_mask = ~(valid_bit_mask);
                        /* Check if trailing bits are untouched (all 1's)*/
                        if ((last_dst_byte & trailing_bit_mask) != trailing_bit_mask) {
                                printf("Trailing bits were overwritten\n");
                                return -1;
                        }
                }
        }

        printf("Correct output\n");
        return 0;
}

int
main(int argc, char **argv)
{
        int ret = 0;
        int exer_selected = 0;
        exercise_t exercises[NUM_EXERCISES] = {
                exercise1,
                exercise2,
                exercise3,
                exercise4,
                exercise5,
                exercise6,
                exercise7,
                exercise8
        };

        if (argc > 1) {
                exer_selected = atoi(argv[1]);
                if (exer_selected > NUM_EXERCISES || exer_selected == 0) {
                        printf("Pick an exercise between 1 and %u\n",
                               NUM_EXERCISES);
                        return -1;
                }
        } else {
                printf("Need to pass exercise number between 1 and %u\n",
                       NUM_EXERCISES);
                return -1;
        }

        ret = exercises[exer_selected - 1]();

        return ret;

}
#ifdef __cplusplus
}
#endif

