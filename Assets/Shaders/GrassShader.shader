Shader "GrassShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Texture", 2D) = "white" {}
        _NormalForce("NormalForce", Range(-2,2)) = 1
        _SpecForce("SpecularForce", Range(0,2)) = 1
        _grassLenght("GrassLenght", Range(0,1)) = 0.5
        _grassHeight("GrassHeight", Range(0,5)) = 0.5
    }
 
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        cull off
 
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma geometry geom
            #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            texture2D _MainTex;
            SamplerState sampler_MainTex;
            texture2D _NormalTex;
            SamplerState sampler_NormalTex;
 
            float _NormalForce;
            float _SpecForce;
            float _grassLenght;
            float _grassHeight;
            struct Attributes
            {
                float4 position :POSITION;
                half2 uv       :TEXCOORD0;
                half3 normal : NORMAL;
                half4 color : COLOR;
            };
 
            struct Varyings 
            {
                float4 positionVAR :SV_POSITION;
                float4 locpositionVAR :COLOR1;
                half2 uvVAR       : TEXCOORD0;
                half3 normalVar : NORMAL;
                half4 colorVar : COLOR0;
            };
 
            Varyings vert(Attributes Input)
            {
                Varyings Output;
                float3 position = Input.position.xyz;
                Output.positionVAR = TransformObjectToHClip(position);
                Output.locpositionVAR = float4(position,1);
                Output.uvVAR = Input.uv;
                Output.colorVar = Input.color;
                Output.normalVar = TransformObjectToWorldNormal(Input.normal);
                return Output;
            }
            [maxvertexcount(32)]
            void geom(triangle Varyings Input[3], inout TriangleStream<Varyings> triStream)
			{
			    Varyings Output;
                Varyings v;
                float dist=0.1;
                for(int j=0;j<9;j++)
                {
                    v.positionVAR= Input[0].positionVAR + float4(j*dist+cos(_Time.z+j)*dist,-_grassHeight,0,0);
                    v.locpositionVAR = Input[0].locpositionVAR;
                    v.uvVAR = Input[0].uvVAR;
                    v.colorVar = Input[0].colorVar;
                    v.normalVar = Input[0].normalVar;
					triStream.Append(v);
                    v.positionVAR= Input[0].positionVAR + float4(-_grassLenght+j*dist,0,0,0);
                    v.colorVar = Input[0].colorVar - float4(0.2,0.2,0.2,0);
					triStream.Append(v);
                    v.positionVAR= Input[0].positionVAR + float4(_grassLenght+j*dist,0,0,0);
                    v.colorVar = Input[0].colorVar - float4(0.2,0.2,0.2,0);
					triStream.Append(v);
                }
 
                for (int i = 0; i < 3; i++)
                {
                    Output = Input[i];
					triStream.Append(Output);
                }
			}
            half4 frag(Varyings Input) :SV_TARGET
            { 
                half4 color = Input.colorVar;
                Light l = GetMainLight();
                half4 normalmap= _NormalTex.Sample(sampler_NormalTex, Input.uvVAR)*2-1;
                float intensity = dot(l.direction, Input.normalVar+ normalmap.xzy* _NormalForce);
 
                float3 viewDirection = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, Input.locpositionVAR).xyz);
                float3 specularReflection;
                if (intensity < 0.0) 
                {
                    specularReflection = float3(0.0, 0.0, 0.0);
                }
                else 
                {
                    specularReflection = l.color * pow(max(0.0, dot(reflect(-l.direction, Input.normalVar + normalmap.xzy),viewDirection)), _SpecForce);
                }
 
                color *= _MainTex.Sample(sampler_MainTex, Input.uvVAR);
                color *= intensity;
                color += float4(specularReflection,0)*0.1;
                return color * Input.colorVar;
            }
 
            ENDHLSL
        }
    }
}
