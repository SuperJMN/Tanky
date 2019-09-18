using Microsoft.Xna.Framework;

namespace TankyReloaded.Actors
{
    internal class RectangleAdapter :IReadonlyRectangle
    {
        private readonly Rectangle rect;

        public RectangleAdapter(Rectangle rect)
        {
            this.rect = rect;
        }

        public double Left => rect.Left;
        public double Top => rect.Top;
        public double Width => rect.Width;
        public double Height => rect.Height;
    }
}