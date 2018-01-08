// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/OutLine2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Diffuse("Diffuse", Color) = (1,1,1,1)  
        	_OutlineCol("OutlineCol", Color) = (1,0,0,1)  
        	_OutlineFactor("OutlineFactor", Range(0,1)) = 0.1  
        	_Color ("Main Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
		LOD 100
		
		Pass
		{
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			fixed4 _OutlineCol;  
            		float _OutlineFactor;  
			#define float_t    half
			#define float2_t   half2
			#define float3_t   half3
			#define float4_t   half4

			// Outline thickness multiplier
			#define INV_EDGE_THICKNESS_DIVISOR 0.00285
			// Outline color parameters
			#define SATURATION_FACTOR 0.6
			#define BRIGHTNESS_FACTOR 0.8

			float4 _Color;
			float4 _LightColor0;
			float _EdgeThickness = 1.0;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.pos = UnityObjectToClipPos(v.vertex);
				//沿着法线的方向对顶点进行外延
				float4 vnormal = UnityObjectToClipPos(float4(v.normal,0));
				vnormal.z += 0.00001;
				o.pos += vnormal * _OutlineFactor;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4_t diffuseMapColor = tex2D(_MainTex,i.uv);
				//获取rgb中对大的值
				float_t maxChan = max(max(diffuseMapColor.r,diffuseMapColor.g),diffuseMapColor.b);
				float4_t newMapColor = diffuseMapColor;
				//最大的值减去1/255,这里是经验公式
				maxChan -= (1.0/255.0);
				//将最大值组成的rgb与原始颜色做差值,在乘以一个放大系数.
				float3_t lerpVals = saturate((newMapColor.rgb - float3(maxChan,maxChan,maxChan)) * 255.0);
				//通过颜色差值在做因子做lerp,当颜色的差值比较大时越靠近原始颜色,否则偏暗.
				newMapColor.rgb = lerp(SATURATION_FACTOR * newMapColor.rgb,newMapColor.rgb,lerpVals);
				return float4(BRIGHTNESS_FACTOR * newMapColor.rgb * diffuseMapColor.rgb,diffuseMapColor.a) * _Color * _LightColor0;

				return newMapColor;
			}

			ENDCG
		}
		Pass
		{
			Cull Back
			CGPROGRAM
			#include "Lighting.cginc"

			fixed4 _Diffuse;  
            		sampler2D _MainTex;  
            		float4 _MainTex_ST;  

            		struct v2f  
            		{  
                		float4 pos : SV_POSITION;  
                		float3 worldNormal : TEXCOORD0;  
                		float2 uv : TEXCOORD1;  
            		};  

            		v2f vert(appdata_base v)  
            		{  
				v2f o;  
                		o.pos = UnityObjectToClipPos(v.vertex);  
                		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
                		o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);  
                		return o;  
            		}  
 
 			fixed4 frag(v2f i) : SV_Target  
			{  
                		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.xyz;  
                		fixed3 worldNormal = normalize(i.worldNormal);  
                		fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  
                		fixed3 lambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                		fixed3 diffuse = lambert * _Diffuse.xyz * _LightColor0.xyz + ambient;  
                		fixed4 color = tex2D(_MainTex, i.uv);  
                		color.rgb = color.rgb;  
                		return fixed4(color);  
            		}  

			#pragma vertex vert  
			#pragma fragment frag     

			ENDCG
		}
	}
	FallBack "Diffuse"
}
