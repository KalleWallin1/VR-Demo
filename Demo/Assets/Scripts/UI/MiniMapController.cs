using UnityEngine;
using UnityEngine.UI;

namespace Assets.Scripts.UI
{
    public class MiniMapController : MonoBehaviour
    {
        [Header("References")]
        public RectTransform mapContent;
        public RectTransform compassLabelsContainer; 
        public UnityEngine.UI.Image viewSectorImage; // New: View Sector UI Image
        public Transform target;

        private static readonly int FOVProperty = Shader.PropertyToID("_FOV");
        private Material _viewSectorMat;

        void Start()
        {
            if (target == null)
            {
                target = Camera.main.transform;
            }

            if (viewSectorImage != null && viewSectorImage.material != null)
            {
                // Create an instance of the material to avoid modifying the asset
                _viewSectorMat = new Material(viewSectorImage.material);
                viewSectorImage.material = _viewSectorMat;
            }
        }

        void Update()
        {
            if (target == null) return;

            // Get the yaw rotation
            float yaw = target.eulerAngles.y;

            // 1. Rotate the map content (grid)
            if (mapContent != null)
            {
                mapContent.localRotation = Quaternion.Euler(0, 0, yaw);
            }

            // 2. Rotate the compass labels container and keep labels upright
            if (compassLabelsContainer != null)
            {
                compassLabelsContainer.localRotation = Quaternion.Euler(0, 0, yaw);
                
                for (int i = 0; i < compassLabelsContainer.childCount; i++)
                {
                    compassLabelsContainer.GetChild(i).localRotation = Quaternion.Euler(0, 0, -yaw);
                }
            }

            // 3. Update View Sector FOV if using Camera
            if (_viewSectorMat != null)
            {
                Camera cam = target.GetComponent<Camera>();
                if (cam == null) cam = Camera.main;
                
                if (cam != null)
                {
                    _viewSectorMat.SetFloat(FOVProperty, cam.fieldOfView);
                }
            }
        }

        private void OnDestroy()
        {
            if (_viewSectorMat != null)
            {
                Destroy(_viewSectorMat);
            }
        }
    }
}
