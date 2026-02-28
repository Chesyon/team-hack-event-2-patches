#include <pmdsky.h>
#include <cot.h>

// Aliases for ARM's compiler functions to instead use the game's functions
// "Indirect aliases" means that I couldn't find a perfect in-game equivalent, so I've written my own.
// Weirdly, ARM's docs list some function names differently then what the compiler tries to use: https://developer.arm.com/documentation/dui0475/c/floating-point-support/
// For example, int to float casts tries to call __aeabi_i2f instead of _fflt.
// This gist by Al-harieamjari seems to line up with what the compiler actually uses: https://gist.github.com/harieamjari/61aa4420ae4ded5e86f5143e46d93573
// So I've based my aliases on that.

/* Standard double precision floating-point
 * arithmetic helper functions
 */
static inline double __attribute__((used)) __aeabi_dadd(double a, double b){
    return _dadd(a, b);
}
static inline double __attribute__((used)) __aeabi_ddiv(double a, double b){
    return _ddiv(a, b);
}
static inline double __attribute__((used)) __aeabi_dmul(double a, double b){
    return _dmul(a, b);
}
static inline double __attribute__((used)) __aeabi_drsub(double a, double b){ // indirect alias
    return _dsub(b, a);
}
static inline double __attribute__((used)) __aeabi_dsub(double a, double b){
    return _dsub(a, b);
}

/* double precision floating-point comparison
 * helper functions
 */
static inline int __attribute__((used)) __aeabi_dcmpeq(double a, double b){
    return _deq(a, b);
}
static inline int __attribute__((used)) __aeabi_dcmplt(double a, double b){
    return _dls(a, b);
}
static inline int __attribute__((used)) __aeabi_dcmple(double a, double b){
    return _dleq(a, b);
}
static inline int __attribute__((used)) __aeabi_dcmpge(double a, double b){ // indirect alias
    return _dleq(b, a);
}
static inline int __attribute__((used)) __aeabi_dcmpgt(double a, double b){
    return _dgr(a, b);
}
static inline int __attribute__((used)) __aeabi_dcmpun(double a, double b){
    return _dneq(a, b);
}

/* Standard single precision floating-point
 * arithmetic helper functions
 */
static inline float __attribute__((used)) __aeabi_fadd(float a, float b) {
    return _fadd(a, b);
}
static inline float __attribute__((used)) __aeabi_fdiv(float a, float b){
    return _fdiv(a, b);
}
static inline float __attribute__((used)) __aeabi_fmul(float a, float b){
    return _fmul(a, b);
}
static inline float __attribute__((used)) __aeabi_frsub(float a, float b){ // indirect alias
    return _fsub(b, a);
}
static inline float __attribute__((used)) __aeabi_fsub(float a, float b){
    return _fsub(a, b);
}

/* Standard single precision floating-point
 * comparison helper functions
 */
static int __attribute__((naked)) __attribute__((used)) __aeabi_fcmpeq(float a, float b){ // manual implementation (could be done using _fls but it would be unnecessarily complicated)
    asm("push {lr}");
    asm("bl _fsub");
    asm("cmp r0,#0");
    asm("movne r0,#0");
    asm("moveq r0,#1");
    asm("pop {pc}");
}
static inline int __attribute__((used)) __aeabi_fcmplt(float a, float b){
    return _fls(a, b);
}
static inline int __attribute__((used)) __aeabi_fcmple(float a, float b){ // indirect alias
    return !_fls(b, a);
}
static inline int __attribute__((used)) __aeabi_fcmpge(float a, float b){ // indirect alias
    return !_fls(a, b);
}
static inline int __attribute__((used)) __aeabi_fcmpgt(float a, float b){ // indirect alias
    return _fls(b, a);
}
static int __attribute__((naked)) __attribute__((used)) __aeabi_fcmpun(float a, float b){ // manual implementation
    asm("push {lr}");
    asm("bl _fsub");
    asm("cmp r0,#0");
    asm("movne r0,#1");
    asm("pop {pc}");
}

/* Standard floating-point to integer
 * conversions
 */
static inline unsigned long long __attribute__((used)) __aeabi_d2ulz(double x){
    return _ll_ufrom_d(x);
}
static inline int32_t __attribute__((used)) __aeabi_f2iz(float x){
    return _ffix(x);
}
static inline uint32_t __attribute__((used)) __aeabi_f2uiz(float x){ // indirect alias
    return (uint32_t)_ffix(x);
}

/* Standard conversions between floating
 * types
 */
static inline float __attribute__((used)) __aeabi_d2f(double x){
    return _d2f(x);
}
static inline double __attribute__((used)) __aeabi_f2d(float x){
    return _f2d(x);
}

 /* Standard integer to floating-point
 * conversions
 */
static inline double __attribute__((used)) __aeabi_i2d(int32_t x){
    return _dflt(x);
}
static inline double __attribute__((used)) __aeabi_ui2d(uint32_t x){
    return _dfltu(x);
}
static inline float __attribute__((used)) __aeabi_i2f(int32_t x){
    return _fflt(x);
}
static inline float __attribute__((used)) __aeabi_ui2f(uint32_t x){
    return _ffltu(x);
}