using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Bomb : StageObject
    {
        private static Texture2D texture;
        private readonly double speed = 300;

        public Bomb()
        {
            Width = 32;
            Height = 32;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Bomb");
        }

        public override void Update(GameTime gameTime)
        {
            if (Top + Height < Constants.GroundTop)
            {
                Top += gameTime.ElapsedGameTime.TotalSeconds * speed;
            }
            else
            {
                Top = Constants.GroundTop - Height;
            }
        }
    }
}