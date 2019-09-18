using Microsoft.Xna.Framework;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    public static class RectangleExtensions
    {
        public static void SetWidth(this IRectangle rectangle, double width, IReadonlyRectangle reference)
        {
            rectangle.Width = width;
            var proportion = reference.Width / reference.Height;
            rectangle.Height = width / proportion;
        }

        public static void SetHeight(this IRectangle rectangle, double height, IReadonlyRectangle reference)
        {
            rectangle.Height = height;
            var proportion = reference.Width / reference.Height;
            rectangle.Height = height * proportion;
        }
    }
}