using Domain;
using NUnit.Framework;

namespace Passing.NUnit.Tests1
{
    [TestFixture]
    public class CalculatorTests
    {
        [Test]
        public void Calculator_should_add_two_values()
        {
            Assert.That(new Calculator().Add(3, 5.5m), Is.EqualTo(8.5m));
        }
    }
}
