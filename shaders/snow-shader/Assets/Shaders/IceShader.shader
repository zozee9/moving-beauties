Shader "Custom/IceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}

        [HDR]
        _RimColor ("Rim Color", Color) = (0.9,0.9,0.9,1) // tint
        _RimAmount ("Rim Amount", Range(0,1)) = 0.716
        //_RimThreshold ("Rim Threshold", Range(0,1)) = 1
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
        }

        Pass {
            //Cull Off // transparent, want to see other side

            Blend SrcAlpha OneMinusSrcAlpha // standard alpha blending

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // object to world space
                o.viewDir = WorldSpaceViewDir(v.vertex); // figure out where it is viewed from

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            float4 _Color;
            float _RimThreshold;
            float _RimAmount;
            float _RimColor;

            float4 frag(v2f i) : SV_Target
            {
                fixed4 startCol = tex2D(_MainTex, i.uv) * _Color; // starting color

                float3 normal = normalize(i.worldNormal); // normalize world normal
                float3 viewDir = normalize(i.viewDir);
                //
                float rimDot = 1 - dot(viewDir, normal); // rim on surfaces facing away from camera (not center)


               if (rimDot > _RimAmount)
               {
                   float rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimDot);
                   float4 rim = rimIntensity * _RimColor;
                   return startCol * rim;
               }

                // if (rimIntensity > 0)
                // {
                //     col.rgb = col.rgb + ((_BrightColor - col.rgb) * _BrightenScale);
                //     return col;
                // }
//                }

                //
                // float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                // rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                // col.rgb = col.rgb + ((_BrightColor - col.rgb) * _BrightenScale);


                float edgeFactor = abs( dot(i.viewDir, i.worldNormal));
                //float edgeIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, edgeFactor)
                float opacity = min(1.0, _Color.a / edgeFactor);
                opacity = pow(opacity, _RimThreshold);

                return startCol;// + edgeFactor;
            }
            ENDCG
        }
    }
}
