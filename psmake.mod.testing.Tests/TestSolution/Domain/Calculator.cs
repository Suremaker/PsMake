namespace Domain
{
    public class Calculator
    {
        public decimal Factorial(uint n)
        {
            return n <= 1 ? 1 : n * Factorial(n - 1);
        }
        public decimal Add(decimal x, decimal y)
        {
            return x + y;
        }
        public decimal Substract(decimal x, decimal y)
        {
            return x - y;
        }
        public decimal Multiply(decimal x, decimal y)
        {
            return x * y;
        }
        public decimal Divide(decimal x, decimal y)
        {
            return x / y;
        }
    }
}
