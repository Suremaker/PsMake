using Domain;
using NUnit.Framework;

namespace Failing.NUnit3.Tests
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_divide_two_values()
        {
            Assert.That(new Calculator().Divide(3, 2), Is.EqualTo(1m));
        }
    }
}
