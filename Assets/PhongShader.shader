Shader "Unlit/PhongShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalTex ("Normal Texture", 2D) = "white" {}
		_LightPos ("Light Position", Vector) = (10, 10, 10)
		_AmbientLight ("Ambient Light", float) = 0.0
		_SpecularReflection ("Specular Reflection", float) = 0.0
		_DiffuseReflection ("Diffuse Reflection", float) = 0.0
        _MaterialShininess ("Material Shininess", float) = 0.0
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv            : TEXCOORD0;
				float3 worldSpacePos : TEXCOORD1;
				float4 pos           : SV_POSITION;
			};

			struct TBN
			{
			    float3 tangent;
			    float3 bitangent;
			    float3 normal;
			};
			
			sampler2D _MainTex;
			sampler2D _NormalTex;
			float4    _MainTex_ST;
			
			float3 _LightPos;
			float  _AmbientLight;
            float  _SpecularReflection;
            float  _DiffuseReflection;
            float  _MaterialShininess;
			
			TBN getOrthonormalBase(const float3 n)
            {
                float n_sign = lerp(sign(n.z), 1, n.z == 0); 
                const float a = -1.0f / (n_sign + n.z);
                const float b = n.x * n.y * a;
                float3 b1 = float3(1.0f + n_sign * n.x * n.x * a, n_sign * b, -n_sign * n.x);
                float3 b2 = float3(b, n_sign + n.y * n.y * a, -n.y);
            
                TBN tbn;
                tbn.tangent   = b1;
                tbn.bitangent = b2;
                tbn.normal    = n;

                return tbn;
            }
			
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldSpacePos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			float getPhongIllumination(float3 normal, float3 pos)
			{
			    float3 L = normalize(_LightPos - pos);
			    float3 N = normalize(normal);
			    float3 R = normalize(reflect(-L, N));
			    float3 V = normalize(_WorldSpaceCameraPos - pos);
				
				float diff = _DiffuseReflection * clamp(max(dot(L, N), 0), 0.0, 1.0);
				float spec = _SpecularReflection * clamp(pow(max(dot(R, V), 0), _MaterialShininess), 0.0, 1.0);
				
				return _AmbientLight + diff + spec;   
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				float3 normal = normalize(tex2D(_NormalTex, i.uv).rgb * 2.0 - 1.0);
			    normal.y *= -1;
			    
			    // Generate TBN
                // @TODO move this to C#
			    TBN tbn_s = getOrthonormalBase(float3(0, 1, 0));			    
			    float4x4 tbn_worldSpace = mul(
			       unity_ObjectToWorld, 
			       float4x4(
			           float4(tbn_s.tangent, 0), 
			           float4(tbn_s.bitangent, 0), 
			           float4(tbn_s.normal, 0), 
			           float4(0, 0, 0, 1)
			       )
			    );
			    
			    float3 normal_worldSpace = mul(tbn_worldSpace, normal);

                float I = getPhongIllumination(normal_worldSpace, i.worldSpacePos);

				return tex2D(_MainTex, i.uv) + I;
			}
			
			ENDCG
		}
	}
}
