Shader "Unlit/motionRaymarching"
{
   Properties {
        _Radius("Radius", Range(0.0, 1.0)) = 0.3
        _BlurShadow("BlurShadow", Range(0.0, 50.0)) = 16.0
        _Speed("Speed", Range(0.0, 10.0)) = 2.0
    }
    SubShader {
        Tags{ "Queue" = "Transparent" "LightMode"="ForwardBase"}
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

            // 球の大きさ
            float _Radius;
            // ブラーの強さ
            float _BlurShadow;
            // 線形補完の速度
            float _Speed;

            // 中心との距離から球を描画
            float sphere(float3 pos) {
                return length(pos) - _Radius;
            }

            // planeの描画
            float plane(float3 pos) {
                // planeの傾き
                float4 n = float4(0.0, 0.8, 0.0, 1.0);
                return dot(pos, n.xyz) + n.w;
            }

            // 正方形の描画
            float box(float3 pos) {
                float3 b = _Radius;
                float3 d = abs(pos) - b;
                return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
            }

            // planeと球との距離
            float getDist(float3 pos) {
                // 正弦波で線形補完
                float time = (sin(_Time.y * _Speed) + 1.0f) * 0.5f;
                float morph = lerp(box(pos), sphere(pos), time);
                return min(plane(pos), morph);
            }

            // 法線を取得
            float3 getNormal(float3 pos) {
                float d = 0.001;
                return normalize(float3(
                    getDist(pos + float3(d, 0, 0)) - getDist(pos + float3(-d, 0, 0)),
                    getDist(pos + float3(0, d, 0)) - getDist(pos + float3(0, -d, 0)),
                    getDist(pos + float3(0, 0, d)) - getDist(pos + float3(0, 0, -d))
                ));
            }

            // 光源に向かってレイを飛ばす
            float genShadow(float3 pos, float3 lightDir) {
                float marchingDist = 0.0;
                float c = 0.001;
                float r = 1.0;
                float shadowCoef = 0.5;
                for (float t = 0.0; t < 50.0; t++) {
                    marchingDist = getDist(pos + lightDir * c);
                    // hitしたら影を落とす
                    if (marchingDist < 0.001) {
                        return shadowCoef;
                    }
                    // 反影の計算
                    r = min(r, marchingDist * _BlurShadow / c);
                    c += marchingDist;
                }
                // hitしなかった場合、反影を描画
                return 1.0 - shadowCoef + r * shadowCoef;
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
                const int StepNum = 30;

                for (int j = 0; j < StepNum; j++) {
                    // レイを進める距離
                    float marchingDist = getDist(pos);
                    // 衝突検知
                    if (marchingDist < 0.001) {
                        float3 lightDir = _WorldSpaceLightPos0.xyz;
                        float3 normal = getNormal(pos);
                        float3 lightColor = _LightColor0;
                        
                        // レイがオブジェクトにめり込むのを防ぐ
                        // https://wgld.org/d/glsl/g020.html
                        float shadow = genShadow(pos + normal * 0.001, lightDir);
                        // 内積によって色を変化させる
                        fixed4 col = fixed4(lightColor * max(dot(normal, lightDir), 0) * max(0.5, shadow), 1.0);
                        // 環境光のオフセット
                        col.rgb += fixed3(0.2f, 0.2f, 0.2f);
                        return col;
                    }
                    // レイを進める
                    pos.xyz += marchingDist * rayDir.xyz;
                }
                // stepNum回レイを進めても衝突しなかったらピクセルを透明にする
                return 0;
            }
            ENDCG
        }
    }
}
