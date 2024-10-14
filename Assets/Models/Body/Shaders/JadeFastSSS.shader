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
                float2 texCoord : TEXCOORD0;
            };

            struct FragIn
            {
                float4 position : SV_POSITION;
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
                o.texCoord = i.texCoord;
                o.worldPos = mul(unity_ObjectToWorld, i.position);
                return o;
            }

            float4 frag (FragIn i) : SV_Target
            {
                float4 diffuse = tex2D(_Diffuse, i.texCoord);
                float4 specular = tex2D(_Diffuse, i.texCoord);
            
                float3 normal = tex2D(_Normal, i.texCoord);
                float ao = tex2D(_AO, i.texCoord);

                float thickness = tex2D(_Thickness, i.texCoord);
                float curvature = tex2D(_Curvature, i.texCoord);

                // float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                float3 lightDir = normalize(_LightPosition - i.worldPos);
                float3 viewDir = normalize(_CameraPosition - i.worldPos);

                float3 halfDir = lightDir + normal * _Distortion;
                float vDotH = pow(saturate(dot(viewDir, -halfDir)), _Power) * _Scale;
                float jadeIllu = _LightAtten * (vDotH + _Ambient) * thickness;

                return diffuse + specular + _LightColor * jadeIllu;
            }
            ENDCG
        }
    }
}
