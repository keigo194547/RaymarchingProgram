Shader "Unlit/OnrySphere_Raymarching"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius("Radius", Range(0.0, 1.0)) = 0.3
    }
        SubShader{
            Tags { "Queue" = "Transparent" "LightMode" = "ForwardBase"}
            LOD 100

            Pass {
                ZWrite On
                Blend SrcAlpha OneMinusSrcAlpha

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"

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

                // 法線を取得
                float3 getNormal(float3 pos) {
                    // δ
                    float d = 0.001;
                    // 法線の公式より、各変数の偏微分から計算
                    return normalize(float3(
                        sphere(pos + float3(d, 0, 0)) - sphere(pos + float3(-d, 0, 0)),
                        sphere(pos + float3(0, d, 0)) - sphere(pos + float3(0, -d, 0)),
                        sphere(pos + float3(0, 0, d)) - sphere(pos + float3(0, 0, -d))));
                }

                v2f vert(appdata v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.pos = mul(unity_ObjectToWorld, v.vertex);
                    o.uv = v.uv;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    float3 pos = i.pos.xyz;
                    // レイのベクトル
                    float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);
                    int stepNum = 30;

                    for (int i = 0; i < stepNum; i++) {
                        // レイを進める距離
                        float marcingDist = sphere(pos);
                        // 衝突検知
                        if (marcingDist < 0.001) {
                            float3 lightDir = _WorldSpaceLightPos0.xyz;
                            float3 normal = getNormal(pos);
                            float3 lightColor = _LightColor0;
                            // 内積によって色を変化させる
                            fixed4 col = fixed4(lightColor * max(dot(normal, lightDir), 0), 1.0);
                            // 環境光のオフセット
                            col.rgb += fixed3(0.2f, 0.2f, 0.2f);
                            return col;
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
