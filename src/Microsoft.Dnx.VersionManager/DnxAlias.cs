using System;
using System.IO;

namespace Microsoft.Dnx.VersionManager
{
    public class DnxAlias
    {
        private static string _aliasDirectoryName = "alias";

        private static string[] _aliasPatterns = new[] { "{0}.alias", "{0}.txt" };

        public string Name { get; set; }

        public string FullPath { get; set; }

        public string RuntimeFullName { get; set; }

        public static string GetAliasPath(string runtimeHome, string aliasName)
        {
            var aliasHome = Path.Combine(runtimeHome, _aliasDirectoryName);
            Directory.CreateDirectory(aliasHome);
            return Path.Combine(aliasHome, $"{aliasName}.alias");
        }

        public static DnxAlias GetAlias(string runtimeHome, string aliasName)
        {
            var aliasPath = GetAliasPath(runtimeHome, aliasName);
            if(!File.Exists(aliasPath))
            {
                return null;
            }

            var runtimeName = File.ReadAllText(aliasPath).Trim();

            return new DnxAlias
            {
                Name = aliasName,
                FullPath = aliasPath,
                RuntimeFullName = runtimeName
            };
        }

        public static void Create(string runtimeHome, string aliasName, string runtimeVersion)
        {
            File.WriteAllText(GetAliasPath(runtimeHome, aliasName), runtimeVersion);
        }

        public static void Delete(string runtimeHome, string aliasName)
        {
            File.Delete(GetAliasPath(runtimeHome, aliasName));
        }
    }
}