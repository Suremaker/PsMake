using Domain;
using Xunit;

namespace Failing.XUnit.Tests
{
    public class CalculatorTests
    {
        [Fact]
        public void Calculator_should_divide_two_values()
        {
            Assert.Equal(1m, new Calculator().Divide(3, 2));
        }
    }
}