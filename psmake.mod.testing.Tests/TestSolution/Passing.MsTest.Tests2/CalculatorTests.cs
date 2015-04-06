using Domain;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Passing.MsTest.Tests2
{
    [TestClass]
    public class CalculatorTests
    {
        [TestMethod]
        public void Calculator_should_multiply_two_values()
        {
            Assert.AreEqual(7.5m, new Calculator().Multiply(3, 2.5m));
        }
    }
}
