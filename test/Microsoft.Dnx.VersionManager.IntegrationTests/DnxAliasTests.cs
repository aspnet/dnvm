using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Microsoft.Dnx.VersionManager.IntegrationTests
{
    public class AliasTestFixture : IDisposable
    {
        public string RuntimeHome { get; private set; }

        public AliasTestFixture()
        {
            RuntimeHome = Path.Combine(Path.GetTempPath(), $"dnvmTests-{DateTime.Now.ToString("yyyyMMdd")}");
            Directory.CreateDirectory(RuntimeHome);
        }

        public void Dispose()
        {
            Directory.Delete(RuntimeHome, true);
        }
    }

    public class DnxAliasTests : IClassFixture<AliasTestFixture>
    {
        AliasTestFixture _fixture;

        public DnxAliasTests(AliasTestFixture fixture)
        {
            _fixture = fixture;
        }

        [Fact]
        public void DnxAliasCanCreateAliasAndReadItBack()
        {
            var runtimeFullName = "dnx-clr-win-x86.1.0.0-dev";
            var aliasName = "DnxAliasCanCreateAlias";

            DnxAlias.Create(_fixture.RuntimeHome, aliasName, runtimeFullName);

            Assert.True(File.Exists(DnxAlias.GetAliasPath(_fixture.RuntimeHome,aliasName)));

            var alias = DnxAlias.GetAlias(_fixture.RuntimeHome, aliasName);

            Assert.Equal(alias.RuntimeFullName, runtimeFullName);
        }

        [Fact]
        public void DnxAliasDeleteDoesntThrowWhenNoAlias()
        {
            var ex = Record.Exception(() =>
            {
                DnxAlias.Delete(_fixture.RuntimeHome, "DnxAliasDeleteDoesntThrowWhenNoAlias");
            });

            Assert.Null(ex);
        }
    }
}
