using Domain;
using NUnit.Framework;

namespace Passing.NUnit.Tests2
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_multiply_two_values()
        {
            Assert.That(new Calculator().Multiply(3, 2.5m), Is.EqualTo(7.5m));
        }
    }
}
