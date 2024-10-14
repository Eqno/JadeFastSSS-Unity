Shader "Custom/JadeFastSSS_Body"
{
    Properties
    {
        _Diffuse("Diffuse", 2D) = "white" {}
        _Specular("Specular", 2D) = "white" {}
        
        _Normal("Normal", 2D) = "white" {}
        _AO("AO", 2D) = "white" {}

        _Thickness("Thickness", 2D) = "white" {}
        _Curvature("Curvature", 2D) = "white" {}

        _DiffuseStrength("DiffuseStrength", Float) = 1
        _SpecularStrength("SpecularStrength", Float) = 1

        _Roughness("Roughness", Float) = 1
        _Fresnel("Fresnel", Vector) = (1, 1, 1, 1)
        _Metallic("Metallic", Float) = 1
       
        _LightColor("LightColor", Color) = (1, 1, 1, 1)
        _Distortion("Distortion", Float) = 1
        _LightAtten("LightAtten", Float) = 1
        _Ambient("Ambient", Float) = 1
        _Power("Power", Float) = 1
        _Scale("Scale", Float) = 1
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

            #define PI 3.14159265359
            #define EPS 1e-6

            float3 TBN(float3 fragPosition, float2 fragTexCoord, float3 fragNormal, float3 texNormal)
            {
                float3 posDx  = ddx(fragPosition);
                float3 posDy  = ddy(fragPosition);
                float3 stx    = ddx(float3(fragTexCoord, 0.0));
                float3 sty    = ddy(float3(fragTexCoord, 0.0));
                float3 T      = (sty.y * posDx - stx.y * posDy) / (stx.x * sty.y - sty.x * stx.y);
                float3 N      = normalize(fragNormal);
                T             = normalize(T - N * dot(N, T));
                float3 B      = normalize(cross(N, T));
                float3x3 TBN  = float3x3(T, B, N);
                return normalize(mul(TBN, normalize(2.0 * texNormal - 1.0)));
            }

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

            float3 _CameraPosition;
            float3 _LightPosition;
            
            sampler2D _Diffuse;
            sampler2D _Specular;
        
            sampler2D _Normal;
            sampler2D _AO;

            sampler2D _Thickness;
            sampler2D _Curvature;

            float _DiffuseStrength;
            float _SpecularStrength;

            float _Roughness;
            float3 _Fresnel;
            float _Metallic;

            float4 _LightColor;
            float _Distortion;
            float _LightAtten;
            float _Ambient;
            float _Power;
            float _Scale;

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
                float4 texDiffuse = tex2D(_Diffuse, i.texCoord);
                float4 texSpecular = tex2D(_Diffuse, i.texCoord);
            
                float3 texNormal = tex2D(_Normal, i.texCoord);
                float texAO = tex2D(_AO, i.texCoord);

                float texThickness = tex2D(_Thickness, i.texCoord);
                float texCurvature = tex2D(_Curvature, i.texCoord);

                float3 lightDir = normalize(_LightPosition - i.worldPos);
                float3 viewDir = normalize(_CameraPosition - i.worldPos);

                float4 diffuse = _DiffuseStrength * texDiffuse;
                float3 brdf = BRDF(TBN(i.position, i.texCoord, i.normal, texNormal), lightDir, viewDir, texSpecular.rgb, _Roughness, _Fresnel, _Metallic);
                float4 specular = _SpecularStrength * float4(brdf, 1);

                float3 halfDir = lightDir + texNormal * _Distortion;
                float vDotH = pow(saturate(dot(viewDir, -halfDir)), _Power) * _Scale;
                float jadeIllu = _LightAtten * (vDotH + _Ambient) * texThickness;

                return diffuse + specular;
            }
            ENDCG
        }
    }
}
