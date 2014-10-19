constant test_factorial=#[
> mixed all=enumerate(6); factorial(all[*]);
(1) Result: ({1, 1, 2, 6, 24, 120})
> factorial(30);
(2) Result: 265252859812191058636308480000000
#];
int factorial(int(0..) n)
{
    return n?`*(@enumerate(n,1,1)):1;
}
