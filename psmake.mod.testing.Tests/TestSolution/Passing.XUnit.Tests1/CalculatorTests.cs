using Domain;
using Xunit;

namespace Passing.XUnit.Tests1
{
    public class CalculatorTests
    {
        [Fact]
        public void Calculator_should_substract_two_values()
        {
            Assert.Equal(2.5m, new Calculator().Substract(5.5m, 3));
        }
    }
}
