using UnityEditor;
using System.IO;
using UnityEditor.AssetImporters;
using UnityEngine;

namespace TCFramework
{
    [ScriptedImporter( 1, "lua" )]
    public class SrtImporter : ScriptedImporter {
        public override void OnImportAsset( AssetImportContext ctx ) {
            TextAsset subAsset = new TextAsset( File.ReadAllText( ctx.assetPath ) );
            ctx.AddObjectToAsset( "text", subAsset );
            ctx.SetMainObject( subAsset );
        }
    }
}