using Domain;
using MbUnit.Framework;

namespace Failing.MbUnit.Tests
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_divide_two_values()
        {
            Assert.AreEqual(1m, new Calculator().Divide(3, 2));
        }
    }
}
