using Microsoft.Xna.Framework;

namespace SuperJMN.MonoGame
{
    public static class TextureMixin
    {
        public static Rectangle GetTile(int column, int row, int width, int height)
        {
            return new Rectangle(width * column, height * row, width, height);
        }
    }
}