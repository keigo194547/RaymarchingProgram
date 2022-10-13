using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;


public class RaymarchingQuadMeshCreator : MonoBehaviour
{
    static readonly string outputPath =
           "Assets/LoopRaymarching/RaymarchingQuad.mesh";
    const int expandBounds = 10000;// �g������T�C�Y

    [MenuItem("Tools/CreateRaymarchingQuadMesh")]

    static void CreateRaymarchingQuadMesh()
    {
        // Mesh��Asset���쐬���܂�
        var mesh = new Mesh
        {
            vertices = new[]
            {
                new Vector3(1f, 1f, 0f),
                new Vector3(-1f, 1f, 0f),
                new Vector3(-1f, -1f, 0f),
                new Vector3(1f, -1f, 0f),
            },
            uv = new[]
            {
                new Vector2(1f, 1f),
                new Vector2(0f, 1f),
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
            },
            triangles = new[] { 0, 1, 2, 2, 3, 0 }
        };
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        // �o�E���f�B���O�{�b�N�X���g�����܂�
        var bounds = mesh.bounds;
        bounds.Expand(expandBounds);
        mesh.bounds = bounds;

        SafeCreateDirectory(Path.GetDirectoryName(outputPath));

        var oldAsset = AssetDatabase.LoadAssetAtPath<Mesh>(outputPath);
        if (oldAsset)
        {
            // ����Asset������ꍇ�͍X�V���܂�
            oldAsset.Clear();// Mesh�A�Z�b�g�X�V�̒��O�� Clear() ���K�v�ł�
            EditorUtility.CopySerialized(mesh, oldAsset);
            AssetDatabase.SaveAssets();
        }
        else
        {
            // �܂�Asset���Ȃ��ꍇ�͐V�K�쐬���܂�
            AssetDatabase.CreateAsset(mesh, outputPath);
            AssetDatabase.Refresh();
        }
    }

    // �f�B���N�g�������݂��Ȃ��ꍇ�ɍ��܂�
    static DirectoryInfo SafeCreateDirectory(string path)
    {
        if (Directory.Exists(path))
        {
            return null;
        }

        return Directory.CreateDirectory(path);
    }

}
