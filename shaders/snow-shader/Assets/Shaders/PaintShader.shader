
Shader "Custom/PaintShader" {

    Properties{
        _MainTex("Main Texture", 2D) = "white" {}
        _PaintMap("PaintMap", 2D) = "white" {} // texture to paint on
        _Height("Height", Range(1,5)) = 1
        _Tess("Tess", Range(1,32)) = 4
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
        }

        Pass
        {
            Lighting Off

            CGPROGRAM
            #pragma vertex vert tessellate:tessFixed
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            struct appdata {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
            };

            sampler2D _PaintMap;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Height;


            float _Tess;

            float4 tessFixed()
            {
                return _Tess;
            }

            v2f vert(appdata v) {
                v2f o;

                float d = tex2Dlod(_PaintMap, float4(v.texcoord1.xy, 0, 0)).r * 0;
                v.vertex.xyz += v.normal * d;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.uv1 = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw; // lightmap uvs

                return o;
            }

            fixed4 frag(v2f o) : COLOR{
                fixed4 main_color = tex2D(_MainTex, o.uv0); // main texture
                fixed4 paint = (tex2D(_PaintMap, o.uv1)); // painted on texture
                main_color *= paint; // add paint to main;
                return main_color;
            }

            ENDCG
        }
    }
}
