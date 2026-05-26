Shader "UI/CompassTicks"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        
        _Heading ("Heading", Float) = 0
        _ViewAngle ("View Angle", Float) = 120
        _TickInterval ("Tick Interval", Float) = 5
        _MajorInterval ("Major Every X Ticks", Float) = 2
        _TickWidth ("Tick Width", Float) = 0.005
        _MajorHeight ("Major Height", Range(0,1)) = 0.8
        _MinorHeight ("Minor Height", Range(0,1)) = 0.4
        [Toggle(_SHOW_BOTTOM_LINE)] _ShowBottomLine ("Show Bottom Line", Float) = 0
        _BottomLineHeight ("Bottom Line Height", Range(0, 0.2)) = 0.05

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
            #pragma shader_feature _SHOW_BOTTOM_LINE

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
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            float _Heading;
            float _ViewAngle;
            float _TickInterval;
            float _MajorInterval;
            float _TickWidth;
            float _MajorHeight;
            float _MinorHeight;
            float _BottomLineHeight;

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

            sampler2D _MainTex;

            float custom_mod(float x, float y)
            {
                return x - y * floor(x / y);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                // Calculate current degree at this UV position
                // Center of UV (0.5) corresponds to _Heading
                float degreesPerUV = _ViewAngle;
                float currentDegree = _Heading + (IN.texcoord.x - 0.5) * degreesPerUV;
                
                // Wrap degrees to 0-360
                float wrappedDegree = custom_mod(currentDegree, 360.0);

                // Tick calculation
                float tickFloat = wrappedDegree / _TickInterval;
                float nearestTick = round(tickFloat);
                float distToTick = abs(tickFloat - nearestTick);
                
                // Handle wrap-around for nearest tick
                // If we are at 359.9 and nearest is 0 (360), the dist should be small
                float totalTicks = 360.0 / _TickInterval;
                float distToTickWrapped = abs(tickFloat - nearestTick);
                if (distToTickWrapped > totalTicks * 0.5) distToTickWrapped = abs(distToTickWrapped - totalTicks);

                // Convert tick distance to UV space distance for width check
                float degreeDist = distToTickWrapped * _TickInterval;
                float uvDist = degreeDist / _ViewAngle;

                float alpha = 0;
                
                #ifdef _SHOW_BOTTOM_LINE
                if(IN.texcoord.y < _BottomLineHeight)
                {
                    alpha = 1.0;
                }
                #endif

                if(uvDist < _TickWidth * 0.5)
                {
                    // It's a tick!
                    // Determine height
                    // For major ticks, check if nearestTick (wrapped) is multiple of _MajorInterval
                    float wrappedNearestTick = custom_mod(nearestTick, totalTicks);
                    bool isMajor = custom_mod(wrappedNearestTick, _MajorInterval) < 0.1;
                    float heightLimit = isMajor ? _MajorHeight : _MinorHeight;
                    
                    bool inHeight = false;
                    #ifdef _SHOW_BOTTOM_LINE
                        inHeight = IN.texcoord.y <= heightLimit;
                    #else
                        inHeight = abs(IN.texcoord.y - 0.5) <= heightLimit * 0.5;
                    #endif

                    if(inHeight)
                    {
                        // Anti-aliasing for width
                        float edgeWidth = _TickWidth * 0.1;
                        float tickAlpha = smoothstep(_TickWidth * 0.5, _TickWidth * 0.5 - edgeWidth, uvDist);
                        alpha = max(alpha, tickAlpha);
                    }
                }

                half4 color = IN.color;
                color.a *= alpha;

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }

        ENDHLSL
        }
    }
}
