Shader "Unlit/WaterUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // _FinalColor ("End Color", Color) = (255,255,255,1)

        _XOffset ("X Offset", Range(0,1)) = 0

        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0,1)) = .777 // plays with unity editor
        _SurfaceNoiseCutoffMinimum("Surface Noise Cutoff Percent Minimum", Range(0,1)) = 0.789

        _SurfaceNoiseCutoffMedium("Surface Noise Cutoff Percent Medium", Range(0,1)) = 1

        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03,0.03,0,0)

        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "TransparentCutout"
            //"ColorType"  = "Multiply"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off // depth test off

            CGPROGRAM
            #define SMOOTHSTEP_AA 0.01 // helps anti-alias

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
                float2 distortUV : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
            };


            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;

            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _XOffset;

            v2f vert (appdata v)
            {
                v2f o;
                float particleAgePercent = v.uv.z;
                o.uv.z = particleAgePercent; // outgoing = ingoing
                o.uv.w = v.uv.w; // this is randomVal

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex.x -= _XOffset * particleAgePercent;

                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);

                o.color = v.color;

                // outgoing uv.z (age percent of particle)

                // noise noise noise
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float _SurfaceNoiseCutoff;
            float _SurfaceNoiseCutoffMinimum;
            float _SurfaceNoiseCutoffMedium;

            float2 _SurfaceNoiseScroll;

            float _SurfaceDistortionAmount;

            //float4 _FinalColor;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                col *= i.color;

                float particleAgePercent = i.uv.z;
                float randomVal = i.uv.w; // this isn't anything?
                //col *= lerp(i.color, _FinalColor, particleAgePercent);

                float2 distortSample = randomVal * (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;
                float2 noiseUV = randomVal * float2((i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);

                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;
                float surfaceNoiseCutoff = lerp(.7, _SurfaceNoiseCutoff, particleAgePercent);
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);

                float alphaSurfaceNoiseScale = 1;
                if (particleAgePercent > _SurfaceNoiseCutoffMedium)
                {
                    alphaSurfaceNoiseScale = .5;
                }
                else if (particleAgePercent > _SurfaceNoiseCutoffMinimum)
                {
                    alphaSurfaceNoiseScale = .75;
                }

                col.a *= alphaSurfaceNoiseScale;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col - surfaceNoise;
            }
            ENDCG
        }
    }
}
