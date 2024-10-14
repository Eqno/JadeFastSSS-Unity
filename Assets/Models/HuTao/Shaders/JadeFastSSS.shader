Shader "Custom/JadeFastSSS_HuTao"
{
    Properties
    {
        _BaseColor("BaseColor", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct VertIn
            {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float2 texCoord : TEXCOORD0;
            };

            struct FragIn
            {
                float4 position : SV_POSITION;
                float3 normal   : NORMAL;
                float2 texCoord : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _BaseColor;
            float4 _CameraPosition;
            float4 _LightPosition;

            #define PI 3.14159265359
            #define EPS 1e-6

            float DistributionGGX(float dnh, float r)
            {
                float a = r * r;
                float _dnh = max(0.0, dnh);
                float dnh_square = _dnh * _dnh;
                return a * a / max(PI * pow(dnh_square * (a * a - 1.0) + 1.0, 2.0), EPS);
            }

            float3 FresnelSchlick(float dvh, float3 f)
            {
                return f + (1.0 - f) * pow(clamp(1.0 - dvh, 0.0, 1.0), 5.0);
            }

            float GeometrySchlickGGX(float dnx, float k)
            {
                return dnx / max(dnx * (1.0 - k) + k, EPS);
            }

            float GeometrySmith(float dnv, float dnl, float r)
            {
                return GeometrySchlickGGX(clamp(dnv, 0.0, 1.0), r / 2.0)
                    * GeometrySchlickGGX(clamp(dnl, 0.0, 1.0), r / 2.0);
            }

            float3 BRDF(float3 normal, float3 light, float3 view,
                float3 color, float roughness, float3 fresnel, float metallic)
            {
                float3 _half = normalize(view + light);
                float dvh = dot(view, _half);
                float dnh = dot(normal, _half);
                float dnl = dot(normal, light);
                float dnv = dot(normal, view);
                float3 _fresnel = lerp(fresnel, color, metallic);

                float D = DistributionGGX(dnh, roughness);
                float3 F = FresnelSchlick(max(dvh, 0.0), _fresnel);
                float G = GeometrySmith(dnv, dnl, roughness);

                float3 specular = D * F * G / max(4.0 * clamp(dnv, 0.0, 1.0) * clamp(dnl, 0.0, 1.0), EPS);
                float3 kd = lerp(float3(1.0, 1.0, 1.0) - F, float3(0.0, 0.0, 0.0), metallic);
                return kd * color / PI + specular;
            }

            FragIn vert (VertIn i)
            {
                FragIn o;
                o.position = UnityObjectToClipPos(i.position);
                o.normal = UnityObjectToWorldNormal(i.normal);
                o.texCoord = i.texCoord;
                o.worldPos = mul(unity_ObjectToWorld, i.position);
                return o;
            }

            float4 frag (FragIn i) : SV_Target
            {
                float _DiffuseStrength = 0.1;
                float _SpecularStrength = 2;
                float _SpecularPower = 1;

                float4 _LightColor = float4(1, 1, 1, 1);
                float _Distortion = 1;
                float _LightAtten = 1;
                float _Ambient = 0;
                float _Power = 1;
                float _Scale = 1;

                float _Roughness = 0.3;
                float3 _Fresnel = float3(0.1, 0.1, 0.1);
                float _Metallic = 0.5;

                float4 texColor = tex2D(_BaseColor, i.texCoord);
                float3 lightDir = normalize(_LightPosition.xyz - i.worldPos);
                float3 viewDir = normalize(_CameraPosition.xyz - i.worldPos);

                float4 diffuse = _DiffuseStrength * texColor;
                float3 brdf = BRDF(i.normal, lightDir, viewDir, texColor.rgb, _Roughness, _Fresnel, _Metallic);
                float4 specular = _SpecularStrength * float4(brdf, 1) * _LightColor;

                float3 halfDir = lightDir + i.normal * _Distortion;
                float vDotH = pow(saturate(dot(viewDir, -halfDir)), _Power) * _Scale;
                float jadeIllu = _LightAtten * (vDotH + _Ambient);

                return specular;
            }
            ENDCG
        }
    }
}
