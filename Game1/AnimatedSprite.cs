using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded
{
    public class AnimatedSprite
    {
        public AnimatedSprite(Texture2D texture, int rows, int columns, int width, int height)
        {
            Texture = texture;
            Rows = rows;
            Columns = columns;
            TotalFrames = rows * columns;
            Width = width;
            Height = height;
        }

        public AnimatedSprite(Texture2D texture, int rows, int columns) : this(texture, rows, columns, texture.Width,
            texture.Height)
        {
        }

        public Texture2D Texture { get; }
        public int Rows { get; }
        public int Columns { get; }

        public int CurrentFrame { get; set; }
        public int TotalFrames { get; set; }

        public int Height { get; }

        public int Width { get; }

        public void Draw(SpriteBatch spriteBatch, Vector2 location)
        {
            var width = Texture.Width / Columns;
            var height = Texture.Height / Rows;
            var row = (int) (CurrentFrame / (float) Columns);
            var column = CurrentFrame % Columns;

            var sourceRectangle = new Rectangle(width * column, height * row, width, height);
            var destinationRectangle = new Rectangle((int) location.X, (int) location.Y, Width, Height);

            spriteBatch.Draw(Texture, destinationRectangle, sourceRectangle, Color.White);
        }
    }
}