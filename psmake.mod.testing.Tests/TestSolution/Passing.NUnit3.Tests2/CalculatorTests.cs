using Domain;
using NUnit.Framework;

namespace Passing.NUnit3.Tests2
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_return_factorial()
        {
            Assert.That(new Calculator().Factorial(3), Is.EqualTo(6));
        }
    }
}
