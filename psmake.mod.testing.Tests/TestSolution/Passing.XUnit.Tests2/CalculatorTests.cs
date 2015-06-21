using Domain;
using Xunit;

namespace Passing.XUnit.Tests2
{
    public class CalculatorTests
    {
        [Fact]
        public void Calculator_should_multiply_two_values()
        {
            Assert.Equal(7.5m, new Calculator().Multiply(3, 2.5m));
        }
    }
}
