using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Microsoft.Dnx.VersionManager.Tests
{
    public class DnxSdkFacts
    {
        [Theory]
        [InlineData("dnx-clr-win-x86.1.0.0-dev")]
        [InlineData("dnx-clr-win-x64.1.0.0-dev")]
        [InlineData("dnx-coreclr-win-arm.1.0.0-dev")]
        [InlineData("dnx-coreclr-win-x86.1.0.0-dev")]
        [InlineData("dnx-coreclr-win-x64.1.0.0-dev")]
        [InlineData("dnx-coreclr-linux-x64.1.0.0-dev")]
        [InlineData("dnx-coreclr-darwin-x64.1.0.0-dev")]
        [InlineData("dnx-coreclr-darwin-x64.1.0.0-dev")]
        [InlineData("dnx-mono.1.0.0-dev")]
        public void GetRuntimeFromFullNameValidName(string fullName)
        {
            var sdk = DnxSdk.GetRuntime(fullName);

            Assert.NotNull(sdk);
            Assert.Equal("1.0.0-dev", sdk.Version);
            Assert.Equal(fullName, sdk.FullName);
        }

        [Fact]
        public void GetRuntimeFromFullNameValidateProperties()
        {
            var sdk = DnxSdk.GetRuntime("dnx-clr-win-x86.1.0.0-dev");

            Assert.NotNull(sdk);
            Assert.Equal("clr", sdk.Flavor);
            Assert.Equal("win", sdk.OperationSystem);
            Assert.Equal("x86", sdk.Architecture);
            Assert.Equal("1.0.0-dev", sdk.Version);
        }

        [Theory]
        [InlineData("foo")]
        [InlineData("dnx----")]
        [InlineData("dnx-dev-ol-8")]
        [InlineData("dnx-x86-win-.os")]
        [InlineData("---.")]
        [InlineData("dnx-1-2-3-4-5-5")]
        [InlineData("dnx-.3.4.-.4.4.")]
        [InlineData("something-clr-win-x86.1.0.0-dev")]
        public void GetRuntimeFromFullNameBadFormat(string fullname)
        {
            var sdk = DnxSdk.GetRuntime(fullname);

            Assert.Null(sdk);
        }
    }
}
