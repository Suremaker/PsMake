using Domain;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Passing.MsTest.Tests1
{
    [TestClass]
    public class CalculatorTests
    {
        [TestMethod]
        public void Calculator_should_add_two_values()
        {
            Assert.AreEqual(8.5m, new Calculator().Add(3, 5.5m));
        }
    }
}
