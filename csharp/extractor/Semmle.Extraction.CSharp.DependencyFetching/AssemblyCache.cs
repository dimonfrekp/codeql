﻿using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Semmle.Extraction.CSharp.DependencyFetching
{
    /// <summary>
    /// Manages the set of assemblies.
    /// Searches for assembly DLLs, indexes them and provides
    /// a lookup facility from assembly ID to filename.
    /// </summary>
    internal class AssemblyCache
    {
        /// <summary>
        /// Locate all reference files and index them.
        /// </summary>
        /// <param name="paths">
        /// Paths to search. Directories are searched recursively. Files are added directly to the
        /// assembly cache.
        /// </param>
        /// <param name="progressMonitor">Callback for progress.</param>
        public AssemblyCache(IEnumerable<string> paths, IEnumerable<string> frameworkPaths, ProgressMonitor progressMonitor)
        {
            this.progressMonitor = progressMonitor;
            foreach (var path in paths)
            {
                if (File.Exists(path))
                {
                    dllsToIndex.Add(path);
                    continue;
                }

                if (Directory.Exists(path))
                {
                    progressMonitor.LogInfo($"Finding reference DLLs in {path}...");
                    AddReferenceDirectory(path);
                }
                else
                {
                    progressMonitor.LogInfo("AssemblyCache: Path not found: " + path);
                }
            }
            IndexReferences(frameworkPaths);
        }

        /// <summary>
        /// Finds all assemblies nested within a directory
        /// and adds them to its index.
        /// (Indexing is performed at a later stage by IndexReferences()).
        /// </summary>
        /// <param name="dir">The directory to index.</param>
        private void AddReferenceDirectory(string dir)
        {
            foreach (var dll in new DirectoryInfo(dir).EnumerateFiles("*.dll", SearchOption.AllDirectories))
            {
                dllsToIndex.Add(dll.FullName);
            }
        }

        /// <summary>
        /// Indexes all DLLs we have located.
        /// Because this is a potentially time-consuming operation, it is put into a separate stage.
        /// </summary>
        private void IndexReferences(IEnumerable<string> frameworkPaths)
        {
            progressMonitor.LogInfo($"Indexing {dllsToIndex.Count} assemblies...");

            // Read all of the files
            foreach (var filename in dllsToIndex)
            {
                IndexReference(filename);
            }

            progressMonitor.LogInfo($"Read {assemblyInfoByFileName.Count} assembly infos");

            foreach (var info in assemblyInfoByFileName.Values
                .OrderBy(info => info.Name)
                .OrderAssemblyInfosByPreference(frameworkPaths))
            {
                foreach (var index in info.IndexStrings)
                {
                    assemblyInfoById[index] = info;
                }
            }
        }

        private void IndexReference(string filename)
        {
            try
            {
                progressMonitor.LogDebug($"Reading assembly info from {filename}");
                var info = AssemblyInfo.ReadFromFile(filename);
                assemblyInfoByFileName[filename] = info;
            }
            catch (AssemblyLoadException)
            {
                progressMonitor.LogInfo($"Couldn't read assembly info from {filename}");
            }
        }

        /// <summary>
        /// Given an assembly id, determine its full info.
        /// </summary>
        /// <param name="id">The given assembly id.</param>
        /// <returns>The information about the assembly.</returns>
        public AssemblyInfo ResolveReference(string id)
        {
            // Fast path if we've already seen this before.
            if (failedAssemblyInfoIds.Contains(id))
                throw new AssemblyLoadException();

            (id, var assemblyName) = AssemblyInfo.ComputeSanitizedAssemblyInfo(id);

            // Look up the id in our references map.
            if (assemblyInfoById.TryGetValue(id, out var result))
            {
                // The string is in the references map.
                return result;
            }

            // Fallback position - locate the assembly by its lower-case name only.
            var asmName = assemblyName.ToLowerInvariant();

            if (assemblyInfoById.TryGetValue(asmName, out result))
            {
                assemblyInfoById[asmName] = result;  // Speed up the next time the same string is resolved
                return result;
            }

            failedAssemblyInfoIds.Add(id);   // Fail early next time

            throw new AssemblyLoadException();
        }

        /// <summary>
        /// All the assemblies we have indexed.
        /// </summary>
        public IEnumerable<AssemblyInfo> AllAssemblies => assemblyInfoByFileName.Select(a => a.Value);

        /// <summary>
        /// Retrieve the assembly info of a pre-cached assembly.
        /// </summary>
        /// <param name="filepath">The filename to query.</param>
        /// <returns>The assembly info.</returns>
        public AssemblyInfo GetAssemblyInfo(string filepath)
        {
            if (assemblyInfoByFileName.TryGetValue(filepath, out var info))
            {
                return info;
            }

            IndexReference(filepath);

            if (assemblyInfoByFileName.TryGetValue(filepath, out info))
            {
                return info;
            }

            throw new AssemblyLoadException();
        }

        private readonly List<string> dllsToIndex = new List<string>();

        private readonly Dictionary<string, AssemblyInfo> assemblyInfoByFileName = new Dictionary<string, AssemblyInfo>();

        // Map from assembly id (in various formats) to the full info.
        private readonly Dictionary<string, AssemblyInfo> assemblyInfoById = new Dictionary<string, AssemblyInfo>();

        private readonly HashSet<string> failedAssemblyInfoIds = new HashSet<string>();

        private readonly ProgressMonitor progressMonitor;
    }
}
