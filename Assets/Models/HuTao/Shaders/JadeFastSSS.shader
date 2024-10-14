Shader "Custom/JadeFastSSS_HuTao"
{
    Properties
    {
        _BaseColor("BaseColor", 2D) = "white" {}
        _DiffuseStrength("DiffuseStrength", Float) = 1
        _SpecularStrength("SpecularStrength", Float) = 1
        _SpecularPower("SpecularPower", Float) = 1

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

            float4 _CameraPosition;
            float4 _LightPosition;

            sampler2D _BaseColor;
            float _DiffuseStrength;
            float _SpecularStrength;
            float _SpecularPower;

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
                float4 texColor = tex2D(_BaseColor, i.texCoord);
                // float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                float3 lightDir = normalize(_LightPosition.xyz - i.worldPos);
                float3 viewDir = normalize(_CameraPosition.xyz - i.worldPos);

                float4 diffuse = _DiffuseStrength * texColor;
                float4 specular = _SpecularStrength * max(0, dot(i.normal, normalize(lightDir + viewDir))) * texColor;

                float3 halfDir = lightDir + i.normal * _Distortion;
                float vDotH = pow(saturate(dot(viewDir, -halfDir)), _Power) * _Scale;
                float jadeIllu = _LightAtten * (vDotH + _Ambient);

                return diffuse + specular + _LightColor * jadeIllu;
            }
            ENDCG
        }
    }
}
