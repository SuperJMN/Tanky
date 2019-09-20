using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace SuperJMN.MonoGame
{
    public class AnimatedSprite
    {
        public AnimatedSprite(Texture2D texture, int columns, int rows, int emptyFrames = 0, int? width = null,
            int? height = null)
        {
            Texture = texture;
            Rows = rows;
            Columns = columns;
            TotalFrames = rows * columns - emptyFrames;

            if (width.HasValue && height.HasValue)
            {
                Width = width.Value;
                Height = height.Value;
            }
            else if (width.HasValue)
            {
                Width = width.Value;
                var proportion = (double)FrameWidth / FrameHeight;
                Height = (int)(width.Value / proportion);
            }
            else if (height.HasValue)
            {
                Height = height.Value;
                var proportion = (double)FrameWidth / FrameHeight;
                Width = (int)(height.Value * proportion);
            }
            else
            {
                Width = FrameWidth;
                Height = FrameHeight;
            }
        }

        public int FrameWidth => Texture.Width / Columns;
        public int FrameHeight => Texture.Height / Rows;

        public Texture2D Texture { get; }
        public int Rows { get; }
        public int Columns { get; }

        public int CurrentFrame { get; set; }
        public int TotalFrames { get; }

        public int Height { get; }

        public int Width { get; }

        public void Draw(SpriteBatch spriteBatch, Vector2 location)
        {
            var row = (int)(CurrentFrame / (float)Columns);
            var column = CurrentFrame % Columns;

            var sourceRectangle = new Rectangle(FrameWidth * column, FrameHeight * row, FrameWidth, FrameHeight);
            var destinationRectangle = new Rectangle((int)location.X, (int)location.Y, Width, Height);

            spriteBatch.Draw(Texture, destinationRectangle, sourceRectangle, Color.White);
        }

        public void Cycle()
        {
            CurrentFrame++;

            if (CurrentFrame >= TotalFrames)
            {
                CurrentFrame = 0;
            }
        }
    }
}