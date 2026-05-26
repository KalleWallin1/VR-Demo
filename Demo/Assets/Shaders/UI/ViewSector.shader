Shader "UI/ViewSector"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,0.5)
        
        _FOV ("Field of View", Range(0, 360)) = 60
        _Radius ("Radius", Range(0, 0.5)) = 0.4
        _Softness ("Softness", Range(0.001, 0.1)) = 0.01
        _EdgeWidth ("Edge Width (Deg)", Range(0, 5)) = 1
        _EdgeColor ("Edge Color", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            float _FOV;
            float _Radius;
            float _Softness;
            float _EdgeWidth;
            fixed4 _EdgeColor;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord - 0.5;
                float dist = length(uv);
                
                // Calculate angle in degrees
                float angle = degrees(atan2(uv.x, uv.y));
                float absAngle = abs(angle);
                float halfFOV = _FOV * 0.5;
                
                // Distance mask
                float distMask = smoothstep(_Radius + _Softness, _Radius, dist);

                // Fill logic
                float angleMask = smoothstep(halfFOV + _Softness * 10, halfFOV, absAngle);
                float fillAlpha = angleMask * distMask;

                // Edge lines logic
                float edgeDist = abs(absAngle - halfFOV);
                float edgeMask = smoothstep(_EdgeWidth, _EdgeWidth - 0.2, edgeDist);
                edgeMask *= step(dist, _Radius); // Clip at radius

                half4 fillCol = IN.color;
                fillCol.a *= fillAlpha;

                half4 edgeCol = _EdgeColor;
                edgeCol.a *= edgeMask;

                // Combine: place edge on top of fill
                half4 color;
                color.rgb = lerp(fillCol.rgb, edgeCol.rgb, edgeCol.a);
                color.a = max(fillCol.a, edgeCol.a);

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
        ENDHLSL
        }
    }
}
