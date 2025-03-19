#include "stdarg.h"
#include "stddef.h"
#include "stdint.h"
#include "stdbool.h"
#include "string.h"
#include "unistd.h"

// Define constants and types
typedef int FILE;
#define stdout ((FILE *)2)
#define STDOUT_PUTC_OFFSET 0x00000000
#define MAXFP1 0xFFFFFFFF
#define HIGHBIT64 (1ull << 63)

typedef struct flags
{
    int plus;
    int space;
    int hash;
} flags_t;

typedef struct printHandler
{
    char c;
    int (*f)(va_list ap, flags_t *f);
} ph;

// Function declarations
void *memcpy(void *dest, const void *src, size_t n);
void pos_libc_putc_stdout(char c);
static void pos_putc(char c);
int fputc(int c, FILE *stream);
int puts(const char *s);
int putchar(int c);
int get_flag(char s, flags_t *f);
char *convert(unsigned long int num, int base, int lowercase);
int print_string(va_list l, flags_t *f);
int print_hex(va_list l, flags_t *f);
int print_hex_big(va_list l, flags_t *f);
int (*get_print(char s))(va_list, flags_t *);
int pos_libc_fputc_locked(int c, FILE *stream);
char *strchr(const char *s, int c);
static inline int isdigit(int a);
static int pos_libc_atoi(char **sptr);
static int pos_libc_reverse_and_pad(char *start, char *end, int minlen);
static int pos_libc_to_x(char *buf, uint32_t n, int base, int minlen);
static int pos_libc_to_udec(char *buf, uint32_t value, int precision);
static int pos_libc_to_dec(char *buf, int32_t value, int fplus, int fspace, int precision);
static inline int isupper(int a);
static void pos_libc_rlrshift(uint64_t *v);
static void pos_libc_ldiv5(uint64_t *v);
static char pos_libc_get_digit(uint64_t *fr, int *digit_count);
static int pos_libc_to_float(char *buf, uint64_t double_temp, int c, int falt, int fplus, int fspace, int precision);
static int pos_libc_to_octal(char *buf, uint32_t value, int alt_form, int precision);
static void pos_libc_uc(char *buf);
static int pos_libc_to_hex(char *buf, uint32_t value, int alt_form, int precision, int prefix);
void *memmove(void *d, const void *s, size_t n);
int pos_libc_prf(int (*func)(), void *dest, char *format, va_list vargs);
int pos_libc_prf_locked(int (*func)(), void *dest, char *format, va_list vargs);
int printf(char *format, ...);
double __extendsfdf2(float a);

// Function definitions
void *memcpy(void *dest, const void *src, size_t n)
{
    char *destc = dest;     // Destination pointer
    const char *srcc = src; // Source pointer

    while (n--) // Copy n bytes from src to dest
        *destc++ = *srcc++;

    return dest; // Return destination pointer
}

void pos_libc_putc_stdout(char c)
{
    extern int putchar_stdout;                         // External variable for stdout
    *(volatile uint32_t *)(long)(&putchar_stdout) = c; // Write character to stdout
}

static void pos_putc(char c)
{
    pos_libc_putc_stdout(c); // Call function to put character to stdout
}

int fputc(int c, FILE *stream)
{
    pos_putc(c); // Put character to stream
    return 0;    // Return success
}

int puts(const char *s)
{
    char c;
    do
    {
        c = *s; // Get character from string
        if (c == 0)
        {                   // If end of string
            pos_putc('\n'); // Print newline
            break;
        }
        pos_putc(c); // Print character
        s++;         // Move to next character
    } while (1);

    return 0; // Return success
}

int putchar(int c)
{
    return fputc(c, stdout); // Put character to stdout
}

int get_flag(char s, flags_t *f)
{
    int i = 0;
    switch (s)
    {
    case '+':
        f->plus = 1; // Set plus flag
        i = 1;
        break;
    case ' ':
        f->space = 1; // Set space flag
        i = 1;
        break;
    case '#':
        f->hash = 1; // Set hash flag
        i = 1;
        break;
    }
    return (i); // Return flag status
}

char *convert(unsigned long int num, int base, int lowercase)
{
    static char *rep;
    static char buffer[50];
    char *ptr;

    rep = (lowercase)
              ? "0123456789abcdef"  // Lowercase representation
              : "0123456789ABCDEF"; // Uppercase representation
    ptr = &buffer[49];
    *ptr = '\0';
    do
    {
        *--ptr = rep[num % base]; // Convert number to string
        num /= base;
    } while (num != 0);

    return (ptr); // Return converted string
}

int print_string(va_list l, flags_t *f)
{
    char *s = va_arg(l, char *);

    (void)f; // Unused parameter

    if (!s)
        s = "(null)"; // Handle null string
    return (puts(s)); // Print string
}

int print_hex(va_list l, flags_t *f)
{
    unsigned int num = va_arg(l, unsigned int);
    char *str = convert(num, 16, 1); // Convert number to hex string
    int count = 0;

    if (f->hash == 1 && str[0] != '0')
        count += puts("0x"); // Print 0x prefix if hash flag is set
    count += puts(str);      // Print hex string
    return (count);          // Return character count
}

int print_hex_big(va_list l, flags_t *f)
{
    unsigned int num = va_arg(l, unsigned int);
    char *str = convert(num, 16, 0); // Convert number to uppercase hex string
    int count = 0;

    if (f->hash == 1 && str[0] != '0')
        count += puts("0X"); // Print 0X prefix if hash flag is set
    count += puts(str);      // Print hex string
    return (count);          // Return character count
}

int (*get_print(char s))(va_list, flags_t *)
{
    ph func_arr[] = {{'s', print_string}, {'x', print_hex}, {'X', print_hex_big}}; // Array of print handlers
    int flags = 3;
    register int i;

    for (i = 0; i < flags; i++)
        if (func_arr[i].c == s)
            return (func_arr[i].f); // Return corresponding print function
    return (NULL);                  // Return NULL if no match found
}

int pos_libc_fputc_locked(int c, FILE *stream)
{
    pos_putc(c); // Put character to stream

    return 0; // Return success
}

char *strchr(const char *s, int c)
{
    char tmp = (char)c;

    while ((*s != tmp) && (*s != '\0'))
        s++; // Find character in string

    return (*s == tmp) ? (char *)s : NULL; // Return pointer to character or NULL
}

static inline int isdigit(int a)
{
    return (((unsigned)(a) - '0') < 10); // Check if character is a digit
}

static int pos_libc_atoi(char **sptr)
{
    register char *p;
    register int i;

    i = 0;
    p = *sptr;
    p--;
    while (isdigit(((int)*p)))
        i = 10 * i + *p++ - '0'; // Convert string to integer
    *sptr = p;
    return i; // Return integer value
}

static int pos_libc_reverse_and_pad(char *start, char *end, int minlen)
{
    int len;

    while (end - start < minlen)
    {
        *end++ = '0'; // Pad with zeros
    }

    *end = 0;
    len = end - start;
    for (end--; end > start; end--, start++)
    {
        char tmp = *end;
        *end = *start;
        *start = tmp; // Reverse string
    }
    return len; // Return length of string
}

static int pos_libc_to_x(char *buf, uint32_t n, int base, int minlen)
{
    char *buf0 = buf;

    do
    {
        int d = n % base;

        n /= base;
        *buf++ = '0' + d + (d > 9 ? ('a' - '0' - 10) : 0); // Convert number to string
    } while (n);
    return pos_libc_reverse_and_pad(buf0, buf, minlen); // Reverse and pad string
}

static int pos_libc_to_udec(char *buf, uint32_t value, int precision)
{
    return pos_libc_to_x(buf, value, 10, precision); // Convert unsigned decimal to string
}

static int pos_libc_to_dec(char *buf, int32_t value, int fplus, int fspace, int precision)
{
    char *start = buf;

    if (value < 0)
    {
        *buf++ = '-';
        if (value != (int32_t)0x80000000)
            value = -value; // Handle negative value
    }
    else if (fplus)
        *buf++ = '+';
    else if (fspace)
        *buf++ = ' ';

    return (buf + pos_libc_to_udec(buf, (uint32_t)value, precision)) - start; // Convert decimal to string
}

static inline int isupper(int a)
{
    return ((unsigned)(a) - 'A') < 26; // Check if character is uppercase
}

static void pos_libc_rlrshift(uint64_t *v)
{
    *v = (*v & 1) + (*v >> 1); // Right logical shift
}

static void pos_libc_ldiv5(uint64_t *v)
{
    uint32_t i, hi;
    uint64_t rem = *v, quot = 0, q;
    static const char shifts[] = {32, 3, 0};
    rem += 2;
    for (i = 0; i < 3; i++)
    {
        hi = rem >> shifts[i];
        q = (uint64_t)(hi / 5) << shifts[i];
        rem -= q * 5;
        quot += q; // Divide by 5
    }
    *v = quot;
}

static char pos_libc_get_digit(uint64_t *fr, int *digit_count)
{
    int rval;
    if (*digit_count > 0)
    {
        *digit_count -= 1;
        *fr = *fr * 10;
        rval = ((*fr >> 60) & 0xF) + '0';
        *fr &= 0x0FFFFFFFFFFFFFFFull; // Get digit from fraction
    }
    else
        rval = '0';
    return (char)(rval); // Return digit
}

static int pos_libc_to_float(char *buf, uint64_t double_temp, int c, int falt, int fplus, int fspace, int precision)
{
    register int decexp;
    register int exp;
    int sign;
    int digit_count;
    uint64_t fract;
    uint64_t ltemp;
    int prune_zero;
    char *start = buf;

    exp = double_temp >> 52 & 0x7ff;          // Extract exponent
    fract = (double_temp << 11) & ~HIGHBIT64; // Extract fraction
    sign = !!(double_temp & HIGHBIT64);       // Extract sign

    if (exp == 0x7ff)
    { // Handle special cases
        if (sign)
        {
            *buf++ = '-';
        }
        if (!fract)
        {
            if (isupper(c))
            {
                *buf++ = 'I';
                *buf++ = 'N';
                *buf++ = 'F';
            }
            else
            {
                *buf++ = 'i';
                *buf++ = 'n';
                *buf++ = 'f';
            }
        }
        else
        {
            if (isupper(c))
            {
                *buf++ = 'N';
                *buf++ = 'A';
                *buf++ = 'N';
            }
            else
            {
                *buf++ = 'n';
                *buf++ = 'a';
                *buf++ = 'n';
            }
        }
        *buf = 0;
        return buf - start;
    }

    if (c == 'F')
    {
        c = 'f';
    }

    if ((exp | fract) != 0)
    {
        exp -= (1023 - 1);
        fract |= HIGHBIT64;
        decexp = true;
    }
    else
        decexp = false;

    if (decexp && sign)
    {
        *buf++ = '-';
    }
    else if (fplus)
    {
        *buf++ = '+';
    }
    else if (fspace)
    {
        *buf++ = ' ';
    }

    decexp = 0;
    while (exp <= -3)
    {
        while ((fract >> 32) >= (MAXFP1 / 5))
        {
            pos_libc_rlrshift(&fract);
            exp++;
        }
        fract *= 5;
        exp++;
        decexp--;

        while ((fract >> 32) <= (MAXFP1 / 2))
        {
            fract <<= 1;
            exp--;
        }
    }

    while (exp > 0)
    {
        pos_libc_ldiv5(&fract);
        exp--;
        decexp++;
        while ((fract >> 32) <= (MAXFP1 / 2))
        {
            fract <<= 1;
            exp--;
        }
    }

    while (exp < (0 + 4))
    {
        pos_libc_rlrshift(&fract);
        exp++;
    }

    if (precision < 0)
        precision = 6;
    prune_zero = false;
    if ((c == 'g') || (c == 'G'))
    {
        if (!falt && (precision > 0))
            prune_zero = true;
        if ((decexp < (-4 + 1)) || (decexp > (precision + 1)))
        {
            if (c == 'g')
                c = 'e';
            else
                c = 'E';
        }
        else
            c = 'f';
    }

    if (c == 'f')
    {
        exp = precision + decexp;
        if (exp < 0)
            exp = 0;
    }
    else
        exp = precision + 1;
    digit_count = 16;
    if (exp > 16)
        exp = 16;

    ltemp = 0x0800000000000000;
    while (exp--)
    {
        pos_libc_ldiv5(&ltemp);
        pos_libc_rlrshift(&ltemp);
    }

    fract += ltemp;
    if ((fract >> 32) & 0xF0000000)
    {
        pos_libc_ldiv5(&fract);
        pos_libc_rlrshift(&fract);
        decexp++;
    }

    if (c == 'f')
    {
        if (decexp > 0)
        {
            while (decexp > 0)
            {
                *buf++ = pos_libc_get_digit(&fract, &digit_count);
                decexp--;
            }
        }
        else
            *buf++ = '0';
        if (falt || (precision > 0))
            *buf++ = '.';
        while (precision-- > 0)
        {
            if (decexp < 0)
            {
                *buf++ = '0';
                decexp++;
            }
            else
                *buf++ = pos_libc_get_digit(&fract, &digit_count);
        }
    }
    else
    {
        *buf = pos_libc_get_digit(&fract, &digit_count);
        if (*buf++ != '0')
            decexp--;
        if (falt || (precision > 0))
            *buf++ = '.';
        while (precision-- > 0)
            *buf++ = pos_libc_get_digit(&fract, &digit_count);
    }

    if (prune_zero)
    {
        while (*--buf == '0')
            ;
        if (*buf != '.')
            buf++;
    }

    if ((c == 'e') || (c == 'E'))
    {
        *buf++ = (char)c;
        if (decexp < 0)
        {
            decexp = -decexp;
            *buf++ = '-';
        }
        else
            *buf++ = '+';
        *buf++ = (char)((decexp / 10) + '0');
        decexp %= 10;
        *buf++ = (char)(decexp + '0');
    }
    *buf = 0;

    return buf - start;
}

static int pos_libc_to_octal(char *buf, uint32_t value, int alt_form, int precision)
{
    char *buf0 = buf;

    if (alt_form)
    {
        *buf++ = '0';
        if (!value)
        {
            *buf++ = 0;
            return 1;
        }
    }
    return (buf - buf0) + pos_libc_to_x(buf, value, 8, precision); // Convert to octal string
}

static void pos_libc_uc(char *buf)
{
    for (; *buf; buf++)
    {
        if (*buf >= 'a' && *buf <= 'z')
        {
            *buf += 'A' - 'a'; // Convert to uppercase
        }
    }
}

static int pos_libc_to_hex(char *buf, uint32_t value, int alt_form, int precision, int prefix)
{
    int len;
    char *buf0 = buf;

    if (alt_form)
    {
        *buf++ = '0';
        *buf++ = 'x';
    }

    len = pos_libc_to_x(buf, value, 16, precision);
    if (prefix == 'X')
    {
        pos_libc_uc(buf0);
    }

    return len + (buf - buf0);
}

void *memmove(void *d, const void *s, size_t n)
{
    char *dest = d;
    const char *src = s;

    if ((size_t)(dest - src) < n)
    {
        while (n > 0)
        {
            n--;
            dest[n] = src[n];
        }
    }
    else
    {
        while (n > 0)
        {
            *dest = *src;
            dest++;
            src++;
            n--;
        }
    }

    return d;
}

int pos_libc_prf(int (*func)(), void *dest, char *format, va_list vargs)
{
    char buf[200 + 1];
    register int c;
    int count;
    register char *cptr;
    int falt;
    int fminus;
    int fplus;
    int fspace;
    register int i;
    int need_justifying;
    char pad;
    int precision;
    int prefix;
    int width;
    char *cptr_temp;
    int32_t *int32ptr_temp;
    int32_t int32_temp;
    uint32_t uint32_temp;
    uint64_t double_temp;

    count = 0;

    while ((c = *format++))
    {
        if (c != '%')
        {
            if ((*func)(c, dest) == -1)
            {
                return -1;
            }

            count++;
        }
        else
        {
            fminus = fplus = fspace = falt = false;
            pad = ' ';
            precision = -1;

            while (strchr("-+ #0", (c = *format++)) != NULL)
            {
                switch (c)
                {
                case '-':
                    fminus = true;
                    break;

                case '+':
                    fplus = true;
                    break;

                case ' ':
                    fspace = true;
                    break;

                case '#':
                    falt = true;
                    break;

                case '0':
                    pad = '0';
                    break;

                case '\0':
                    return count;
                }
            }

            if (c == '*')
            {
                width = (int32_t)va_arg(vargs, int32_t);
                if (width < 0)
                {
                    fminus = true;
                    width = -width;
                }
                c = *format++;
            }
            else if (!isdigit(c))
                width = 0;
            else
            {
                width = pos_libc_atoi(&format);
                c = *format++;
            }

            if ((unsigned)width > 200)
            {
                width = 200;
            }

            if (c == '.')
            {
                c = *format++;
                if (c == '*')
                {
                    precision = (int32_t)
                        va_arg(vargs, int32_t);
                }
                else
                    precision = pos_libc_atoi(&format);

                if (precision > 200)
                    precision = -1;
                c = *format++;
            }

            if (strchr("hlLz", c) != NULL)
            {
                i = c;
                c = *format++;
            }

            need_justifying = false;
            prefix = 0;
            switch (c)
            {
            case 'c':
                buf[0] = (char)((int32_t)va_arg(vargs, int32_t));
                buf[1] = '\0';
                need_justifying = true;
                c = 1;
                break;

            case 'd':
            case 'i':
                int32_temp = (int32_t)va_arg(vargs, int32_t);
                c = pos_libc_to_dec(buf, int32_temp, fplus, fspace, precision);
                if (fplus || fspace || (int32_temp < 0))
                    prefix = 1;
                need_justifying = true;
                if (precision != -1)
                    pad = ' ';
                break;

            case 'e':
            case 'E':
            case 'f':
            case 'F':
            case 'g':
            case 'G':
            {
                union
                {
                    double d;
                    uint64_t i;
                } u;

                u.d = (double)va_arg(vargs, double);
                double_temp = u.i;
            }

                c = pos_libc_to_float(buf, double_temp, c, falt, fplus,
                                      fspace, precision);
                if (fplus || fspace || (buf[0] == '-'))
                    prefix = 1;
                need_justifying = true;
                break;

            case 'n':
                int32ptr_temp = (int32_t *)va_arg(vargs, int32_t *);
                *int32ptr_temp = count;
                break;

            case 'o':
                uint32_temp = (uint32_t)va_arg(vargs, uint32_t);
                c = pos_libc_to_octal(buf, uint32_temp, falt, precision);
                need_justifying = true;
                if (precision != -1)
                    pad = ' ';
                break;

            case 'p':
                uint32_temp = (uint32_t)va_arg(vargs, uint32_t);
                c = pos_libc_to_hex(buf, uint32_temp, true, 8, (int)'x');
                need_justifying = true;
                if (precision != -1)
                    pad = ' ';
                break;

            case 's':
                cptr_temp = (char *)va_arg(vargs, char *);
                for (c = 0; c < 200; c++)
                {
                    if (cptr_temp[c] == '\0')
                    {
                        break;
                    }
                }
                if ((precision >= 0) && (precision < c))
                    c = precision;
                if (c > 0)
                {
                    memcpy(buf, cptr_temp, (size_t)c);
                    need_justifying = true;
                }
                break;

            case 'u':
                uint32_temp = (uint32_t)va_arg(vargs, uint32_t);
                c = pos_libc_to_udec(buf, uint32_temp, precision);
                need_justifying = true;
                if (precision != -1)
                    pad = ' ';
                break;

            case 'x':
            case 'X':
                uint32_temp = (uint32_t)va_arg(vargs, uint32_t);
                c = pos_libc_to_hex(buf, uint32_temp, falt, precision, c);
                if (falt)
                    prefix = 2;
                need_justifying = true;
                if (precision != -1)
                    pad = ' ';
                break;

            case '%':
                if ((*func)('%', dest) == -1)
                {
                    return -1;
                }

                count++;
                break;

            case 0:
                return count;
            }

            if (c >= 200 + 1)
                return -1;

            if (need_justifying)
            {
                if (c < width)
                {
                    if (fminus)
                    {
                        for (i = c; i < width; i++)
                            buf[i] = ' ';
                    }
                    else
                    {
                        (void)memmove((buf + (width - c)), buf, (size_t)(c + 1));
                        if (pad == ' ')
                            prefix = 0;
                        c = width - c + prefix;
                        for (i = prefix; i < c; i++)
                            buf[i] = pad;
                    }
                    c = width;
                }

                for (cptr = buf; c > 0; c--, cptr++, count++)
                {
                    if ((*func)(*cptr, dest) == -1)
                        return -1;
                }
            }
        }
    }
    return count;
}

int pos_libc_prf_locked(int (*func)(), void *dest, char *format, va_list vargs)
{
    int err;
    err = pos_libc_prf(func, dest, format, vargs);
    return err;
}

int printf(char *format, ...)
{
    va_list vargs;
    int r;
    va_start(vargs, format);
    r = pos_libc_prf_locked(pos_libc_fputc_locked, ((void *)stdout), format, vargs);
    va_end(vargs);
    return r;
}

double __extendsfdf2(float a)
{
    return (double)a;
}
