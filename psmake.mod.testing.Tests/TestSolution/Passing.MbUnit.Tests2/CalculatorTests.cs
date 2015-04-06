using Domain;
using MbUnit.Framework;

namespace Passing.MbUnit.Tests2
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_multiply_two_values()
        {
            Assert.AreEqual(7.5m, new Calculator().Multiply(3, 2.5m));
        }
    }
}
