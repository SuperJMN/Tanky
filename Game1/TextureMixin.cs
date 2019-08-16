using Microsoft.Xna.Framework;

namespace Game1
{
    public static class TextureMixin
    {
        public static Rectangle GetTile(int column, int row, int width, int height)
        {
            return new Rectangle(width * column, height * row, width, height);
        }
    }
}