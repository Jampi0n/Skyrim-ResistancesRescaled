using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;
using System;
using System.IO;
using Noggog;
using Newtonsoft.Json.Linq;

namespace MyMod
{
    class Program
    {
		static void EditMod(SkyrimMod mod, SkyrimRelease release)
		{
			// Your code here
		}
		
        static bool DirectoryContainsFile(string directory, string fileName)
        {
            var files = Directory.GetFiles(directory, fileName);
            return files.Length > 0;
        }
        static string FindRootDirectory()
        {
            string current = Directory.GetCurrentDirectory();
            while (!DirectoryContainsFile(current, "project.json")) {
                current = Directory.GetParent(current).FullName;
            }
            return current;
        }

        static void BuildMod(SkyrimRelease release)
        {
            var skyrimPathVar = release == SkyrimRelease.SkyrimLE ? "SkyrimLEPath" : "SkyrimSEPath";
            var skyrimPath = Environment.GetEnvironmentVariable(skyrimPathVar);
            var skyrimEsmPath = skyrimPath + "\\Data\\Skyrim.esm";
            using ISkyrimModDisposableGetter skyrimESM = SkyrimMod.CreateFromBinaryOverlay(skyrimEsmPath, release);

            var jsonContent = File.ReadAllText(FindRootDirectory() + "\\project.json");
            var rss = JObject.Parse(jsonContent);

            string output = (string) rss["output"];
            string esp = (string) rss["esp"];
            Console.WriteLine(Directory.GetCurrentDirectory());
            var modPathVar = release == SkyrimRelease.SkyrimLE ? "SkyrimLEModPath" : "SkyrimSEModPath";
            var modPath = Environment.GetEnvironmentVariable(modPathVar);
            var pluginPath = modPath + "\\" + output + "\\" + esp;


            var mod = new SkyrimMod(ModKey.FromNameAndExtension(Path.GetFileName(pluginPath)), release);
			EditMod(mod, release);

            Directory.CreateDirectory(modPath + "\\" + output);
            mod.WriteToBinaryParallel(pluginPath);
            Console.WriteLine($"Wrote out mod to: {new FilePath(pluginPath).Path}");
        }
        static void Main(string[] _)
        {
            BuildMod(SkyrimRelease.SkyrimLE);
            BuildMod(SkyrimRelease.SkyrimSE);
        }
    }
}
