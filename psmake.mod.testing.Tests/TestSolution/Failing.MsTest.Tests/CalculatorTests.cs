using Domain;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Failing.MsTest.Tests
{
    [TestClass]
    public class CalculatorTests
    {
        [TestMethod]
        public void Calculator_should_divide_two_values()
        {
            Assert.AreEqual(1m, new Calculator().Divide(3, 2));
        }
    }
}
