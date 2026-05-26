using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

namespace Assets.Scripts.UI
{
    public class CompassController : MonoBehaviour
    {
        [Header("References")]
        public RawImage compassStrip;
        public UnityEngine.UI.Image compassShaderImage; 
        public Transform target;

        [Header("Mils & Labels")]
        public TextMeshProUGUI milsText;
        public RectTransform labelsContainer;
        public float pixelsPerDegree = 10.333f; 
        public float headingOffset = 0f;

        [Header("Label Settings")]
        public List<DirectionLabel> directionLabels = new List<DirectionLabel>();

        [System.Serializable]
        public class DirectionLabel
        {
            public RectTransform rect;
            public float angle;
        }

        private static readonly int HeadingProperty = Shader.PropertyToID("_Heading");
        private Material _instancedMaterial;

        void Start()
        {
            if (target == null)
            {
                target = Camera.main.transform;
            }

            if (compassShaderImage != null && compassShaderImage.material != null)
            {
                _instancedMaterial = new Material(compassShaderImage.material);
                compassShaderImage.material = _instancedMaterial;
            }

            // If labels are not manually assigned, try to find them by name under labelsContainer
            if (directionLabels.Count == 0 && labelsContainer != null)
            {
                foreach (RectTransform child in labelsContainer)
                {
                    string n = child.name.ToUpper();
                    float angle = -1;
                    if (n.Contains("_N")) angle = 0;
                    else if (n.Contains("_E")) angle = 90;
                    else if (n.Contains("_S")) angle = 180;
                    else if (n.Contains("_W")) angle = 270;

                    if (angle != -1)
                    {
                        directionLabels.Add(new DirectionLabel { rect = child, angle = angle });
                    }
                }
            }
        }

        void Update()
        {
            if (target == null) return;

            // Get the yaw rotation and apply offset
            float rawYaw = target.eulerAngles.y;
            float yaw = (rawYaw + headingOffset + 360f) % 360f;

            // 1. Update Material Property (Shader approach)
            if (_instancedMaterial != null)
            {
                _instancedMaterial.SetFloat(HeadingProperty, yaw);
            }

            // 2. Update Mils Text
            if (milsText != null)
            {
                float mils = (yaw / 360f) * 6400f;
                milsText.text = Mathf.RoundToInt(mils).ToString("D4"); // Format as 0000
            }

            // 3. Update Labels Position Individually
            if (directionLabels != null)
            {
                foreach (var label in directionLabels)
                {
                    if (label.rect == null) continue;

                    // Calculate relative angle (-180 to 180)
                    float deltaAngle = Mathf.DeltaAngle(yaw, label.angle);
                    
                    // Convert to pixels
                    float xPos = deltaAngle * pixelsPerDegree;

                    // Apply position
                    label.rect.anchoredPosition = new Vector2(xPos, label.rect.anchoredPosition.y);

                    // Optional: Hide if way off-screen to save on layout (though uGUI does this somewhat)
                    // Window is 1240, so half is 620.
                    label.rect.gameObject.SetActive(Mathf.Abs(xPos) < 700);
                }
            }

            // 4. Update old Texture strip if it exists
            if (compassStrip != null)
            {
                float uvX = yaw / 360f;
                Rect uvRect = compassStrip.uvRect;
                uvRect.x = uvX - (uvRect.width / 2f);
                compassStrip.uvRect = uvRect;
            }
        }

        private void OnDestroy()
        {
            if (_instancedMaterial != null)
            {
                Destroy(_instancedMaterial);
            }
        }
    }
}


