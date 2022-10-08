Shader "Unlit/first"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius("Radius", Range(0.0, 1.0)) = 0.3
    }
    SubShader {
        Tags { "Queue"="Transparent" "LightMode"="ForwardBase"}
        LOD 100

        Pass {
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 pos : POSITION1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Radius;

            // 中心との距離から円を描画
            float sphere(float3 pos) {
                return length(pos) - _Radius;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 pos = i.pos.xyz;
                // レイのベクトル
                float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);
                int stepNum = 30;

                for (int i = 0; i < stepNum; i++) {
                    // レイを進める距離
                    float marcingDist = sphere(pos);
                    // 衝突したら、ピクセルを白くする
                    if (marcingDist < 0.0001) {
                        return 1.0;
                    }
                    // レイを進める
                    pos.xyz += marcingDist * rayDir.xyz;
                }
                // stepNum回レイを進めても衝突しなかったらピクセルを透明にする
                return 0;
            }
            ENDCG
        }
    }
}
