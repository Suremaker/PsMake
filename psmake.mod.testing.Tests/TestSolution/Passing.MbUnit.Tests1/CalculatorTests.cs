using Domain;
using MbUnit.Framework;

namespace Passing.MbUnit.Tests1
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_add_two_values()
        {
            Assert.AreEqual(8.5m, new Calculator().Add(3, 5.5m));
        }
    }
}
