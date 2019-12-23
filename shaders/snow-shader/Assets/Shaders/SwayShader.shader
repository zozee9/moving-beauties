Shader "Custom/SwayShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}

        _Speed("Sway Speed",Range(10,25)) = 10
        _Rigidness("Rigidness",Range(1,50)) = 25
        _SwayMax("Sway Max",Range(0,0.01)) = 0.05
        _YOffset("Y Offset", float) = 0.5
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                //"DisableBatching" = "True"
            }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                float3 snowNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;

                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 _SnowAngle;
            float _SnowAmount;
            float _SnowThickness;

            float _Speed;
            float _Rigidness;
            float _SwayMax;
            float _YOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.snowNormal = normalize(_SnowAngle);

                float3 wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float x = sin(wpos.x/_Rigidness + (_Time.x*_Speed))*(v.vertex.y-_YOffset)*5;
                float z = sin(wpos.z/_Rigidness + (_Time.x*_Speed))*(v.vertex.y-_YOffset)*5;

                v.vertex.x += step(0,v.vertex.y - _YOffset) * x * _SwayMax;
                v.vertex.z += step(0,v.vertex.y - _YOffset) * z * _SwayMax;

                if (dot(o.snowNormal, normalize(v.normal)) >= _SnowAmount)
                {
                    v.vertex.xyz += normalize(v.normal) * _SnowThickness;
                }

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // object to world space
                o.viewDir = WorldSpaceViewDir(v.vertex); // figure out where it is viewed from

                TRANSFER_SHADOW(o)

                return o;
            }

            float4 _Color;
            float4 _AmbientColor;
            float4 _BrightColor;
            float4 _SnowColor;
            int _Glossiness;
            float _RimAmount;
            float _RimThreshold;

            float _BrightenScale;

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 startCol = tex2D(_MainTex, i.uv) * _Color; // starting color
                fixed4 col = startCol;

                float3 normal = normalize(i.worldNormal); // normalize world normal

                // SNOW FIRST, no need to fancy toon stuff if there's snow :)
                //float3 snowAngle = normalize(_SnowAngle);
                if (dot(i.snowNormal, normal) >= _SnowAmount)
                {
                    startCol = _SnowColor;
                    //return _SnowColor + _LightColor0;
                }

                float NdotL = dot(_WorldSpaceLightPos0, normal);
                //_WorldSpaceLightPos0 is directional light!
                // where the light is does not matter, only the direction of the light
                // only the first light? kinda odd

                float shadow = SHADOW_ATTENUATION(i);

                float lightIntensity = smoothstep(0, 0.015, NdotL) * smoothstep(0, 0.001, shadow);
                float4 light = lightIntensity * _LightColor0; // add color of light

                col = startCol * (_AmbientColor + light);

                float3 viewDir = normalize(i.viewDir);

                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);

                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);

                //float4 specular = float4(specularIntensitySmooth * _BrightColor.rgb,1); // actual color doesn't affect anything, only gray of the color? odd
                if (specularIntensitySmooth > 0)
                {
                    col.rgb = col.rgb + ((_BrightColor - col.rgb) * _BrightenScale);
                    return float4(col.rgb,1);
                }

                float rimDot = 1 - dot(viewDir, normal); // rim on surfaces facing away from camera (not center)

                if (rimDot > _RimAmount && lightIntensity > 0)
                {
                    float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                    rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                    if (rimIntensity > 0)
                    {
                        col.rgb = col.rgb + ((_BrightColor - col.rgb) * _BrightenScale);
                        return float4(col.rgb,1);
                    }
                }

                return float4(col.rgb,1);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
