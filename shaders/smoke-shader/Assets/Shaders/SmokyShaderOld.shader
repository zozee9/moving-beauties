Shader "Custom/SmokyShaderOld"
{
    Properties
    {
        [HDR]
        _AmbientColor ("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [HDR]
        _OutlineColor ("Outline Color", Color) = (0.9,0.9,0.9,1) // outline smoke darker

        _Glossiness ("Glossiness", Range(25,50)) = 32
        _SpecularThreshold ("Specular Threshold", Range(0,1)) = .1
        _SpecularAmount ("Specular Amount", Range(0,1)) = 0.716
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "LightMode"  = "ForwardBase"
            "PassFlags"  = "OnlyDirectional"
        }
        Pass
        {
            CGPROGRAM
            #define SMOOTHSTEP_AA 0.01 // helps anti-alias

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD0;

                SHADOW_COORDS(1)
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex); // figure out where it is viewed from

                o.color = v.color;

                TRANSFER_SHADOW(o)

                return o;
            }

            float4 _AmbientColor;
            float4 _OutlineColor;

            float _Glossiness;
            float _SpecularThreshold;
            float _SpecularAmount;

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 origColor = i.color;
                fixed4 col = i.color;

                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);

                float shadow = SHADOW_ATTENUATION(i);

                float lightIntensity = smoothstep(0, 0.015, NdotL) * smoothstep(0, 0.001, shadow);
                float4 light = lightIntensity * _LightColor0; // add color of light

                float3 ambientColor = _AmbientColor.a * _AmbientColor.rgb;

                col.rgb *= (ambientColor + light.rgb);

                float3 viewDir = normalize(i.viewDir);
                float rimDot = 1 - dot(viewDir, normal);

                // outline
                float rimIntensity = smoothstep(.7 - 0.01, .7 + 0.01, rimDot);
                if (rimIntensity > 0)
                {
                    col.rgb = origColor.rgb + (_OutlineColor - origColor.rgb);
                    return col;
                }

                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);

                if (rimDot > _SpecularAmount && lightIntensity > 0)
                {
                    float specularIntensity = rimDot * pow(NdotL, _SpecularThreshold);
                    specularIntensity = smoothstep(_SpecularAmount - 0.01, _SpecularAmount + 0.01, specularIntensity);
                    if (specularIntensity > 0)
                    {
                        float4 white = float4(1,1,1,1);
                        return white;
                    }
                }

                return col; // just return it
            }

            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

    }
}
